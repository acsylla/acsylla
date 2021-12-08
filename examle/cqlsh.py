#!/usr/bin/env python3

import argparse
import asyncio
import atexit
import csv
import os
import readline
import sys

__version__ = "0.0.1"

from dataclasses import asdict


class Colors:
    RED = "\033[0;0;31m"
    BRED = "\033[0;1;31m"
    GREEN = "\033[0;0;32m"
    BGREEN = "\033[0;1;32m"
    YELLOW = "\033[0;0;33m"
    BYELLOW = "\033[0;1;33m"
    BLUE = "\033[0;1;34m"
    MAGENTA = "\033[0;1;35m"
    CYAN = "\033[0;1;36m"
    WHITE = "\033[0;1;37m"
    DARK_MAGENTA = "\033[0;35m"
    BOLD = "\033[1m"
    RESET = "\033[0m"


try:
    import acsylla
except ImportError:
    print(f'{Colors.RED}ERROR: Cannot import acsylla. Please install package "pip install acsylla"{Colors.RESET}')
    exit(1)


class Printer:
    def colorize(self, value):
        if isinstance(value, bool):
            if value:
                return Colors.BLUE
            return Colors.BRED
        elif isinstance(value, int):
            return Colors.GREEN
        elif isinstance(value, str):
            return Colors.BYELLOW
        elif value is None:
            return Colors.RED
        else:
            return Colors.RESET

    def table(self, header, rows):
        max_len = list(map(max, *[[len(str(k)) for k in row] for row in rows + [header]]))
        f_header = " "
        f_values = " "
        for i, v in zip(max_len, rows[0]):
            f_header += f"{Colors.BOLD}{{:<{i}}}{Colors.RESET} | "
            f_values += f"{self.colorize(v)}{{:>{i}}}{Colors.RESET} | "
        print("\n" + f_header.format(*header), end="\b\b \n")
        print(" " + "-+-".join(["-" * k for k in max_len]))
        for row in rows:
            print(f_values.format(*map(str, row)), end="\b\b \n")

    def dict(self, d):
        self.table(["key", "value"], list(d.items()))


class AcsyllaCQLSH:
    def __init__(self, args):
        self.cluster_args = {k: v for k, v in args.__dict__.items() if k not in ("keyspace",)}
        self.session_args = {k: v for k, v in args.__dict__.items() if k in ("keyspace",)}
        self.cluster = None
        self.session = None
        self.keyspace = self.session_args["keyspace"]
        self.print = Printer()

    async def init(self):
        self.cluster = acsylla.create_cluster(**self.cluster_args)
        self.session = await self.cluster.create_session(**self.session_args)
        print("cluster_version=>", self.session.version())
        print("snapshot_version=>", self.session.snapshot_version())
        keyspaces = self.session.get_keyspaces()
        print("keyspaces", list(keyspaces))
        print("client_id:", self.session.get_client_id())
        print("get_tables:", list(self.session.get_tables()))

    def get_input_prefix(self):
        return (
            f'{self.cluster_args["username"]}@'
            f'{self.cluster_args["contact_points"][0]}'
            f"/{self.session.get_keyspace()}> "
        )

    def init_tty(self):
        history = os.path.join(os.path.expanduser("~"), ".acsylla_history")
        try:
            readline.read_history_file(history)
            h_len = readline.get_current_history_length()
        except FileNotFoundError:
            open(history, "wb").close()
            h_len = 0

        def save(prev_h_len, history):
            new_h_len = readline.get_current_history_length()
            readline.set_history_length(1000)
            readline.append_history_file(new_h_len - prev_h_len, history)

        atexit.register(save, h_len, history)

        def autocomplete(text, state):
            keywords = [
                "DATE",
                "DELETE",
                "DESC",
                "DESCRIBE",
                "KEYWORDS",
                "BEGIN",
                "KEYSPACE",
                "KEYSPACES",
                "SCHEMA",
                "SELECT",
                "UUID",
                "TIMESTAMP",
                "BATCH",
                "ASCII",
                "TRUNCATE",
                "ALTER",
                "INT",
                "DROP",
                "USER",
                "USERS",
                "AGGREGATES",
                "COLUMNFAMILY",
                "CREATE",
                "FUNCTIONS",
                "TIME",
                "MATERIALIZED",
                "FUNCTION",
                "ROLES",
                "COUNTER",
                "UPDATE",
                "BOOLEAN",
                "AGGREGATE",
                "PERMISSIONS",
                "GRANT",
                "TYPE",
                "USE",
                "VIEW",
                "ROLE",
                "TABLE",
                "TYPES",
                "BLOB",
                "LIST",
                "INSERT",
                "APPLY",
                "JSON",
                "INDEX",
                "TRIGGER",
                "TEXT",
                "REVOKE",
                "FROM",
            ]
            options = [i.upper() for i in keywords if i.startswith(text.upper())]
            if state < len(options):
                return options[state]
            else:
                return None

        readline.parse_and_bind("tab: complete")
        readline.set_completer(autocomplete)

    def describe(self, query):
        query = query.replace(";", "")
        if query.endswith("keyspaces"):
            self.print.table(["keyspaces"], [[k] for k in self.session.get_keyspaces()])
        elif query.endswith("tables"):
            self.print.table(["tables"], [[k] for k in self.session.get_tables()])

    async def tty(self):
        self.init_tty()
        await self.init()
        while True:
            try:
                input_str = input(self.get_input_prefix())
            except (KeyboardInterrupt, EOFError):
                print("Bye!")
                break
            input_str = input_str.strip().lower()
            if input_str == "/m" or input_str.startswith("show metrics"):
                self.print.dict(asdict(self.session.metrics()))
                continue
            elif input_str == "/s" or input_str.startswith("show settings"):
                self.print.dict(self.cluster_args)
                self.print.dict(self.session_args)
                continue
            elif input_str in ("/?", "?", "help"):
                print("Available commands:")
                print("\t/m - show session metrics")
                print("\t/s - show connection settings")
                continue
            else:
                query = input_str
            if not query:
                continue
            elif query.startswith("desc"):
                self.describe(query)
                continue
            elif query.startswith("use"):
                _, keyspace = query.replace(";", "").split()
                try:
                    await self.session.set_keyspace(keyspace)
                except (acsylla.errors.CassErrorServerSyntaxError, acsylla.errors.CassErrorServerInvalidQuery) as e:
                    print(f"{Colors.RED}{e.args}{Colors.RESET}")
                continue
            statement = acsylla.create_statement(query, page_size=10)
            result = None
            try:
                result = await self.session.execute(statement)
            except (acsylla.errors.CassErrorServerSyntaxError, acsylla.errors.CassErrorServerInvalidQuery) as e:
                print(f"{Colors.RED}{e.args}{Colors.RESET}")
            count = 0
            if result:
                while result:
                    count += len(result)
                    self.print.table(result.columns_names(), [row.as_list() for row in result])
                    if result.has_more_pages():
                        try:
                            input("\n---MORE---")
                        except (EOFError, KeyboardInterrupt):
                            print()
                            break
                        statement.set_page_state(result.page_state())
                        result = await self.session.execute(statement)
                        continue
                    print(f"\n({count} rows)")
                    break

    async def stdin(self):
        await self.init()
        for query in sys.stdin:
            statement = acsylla.create_statement(query, page_size=10)
            result = await self.session.execute(statement)
            if result:
                writer = csv.writer(sys.stdout)
                writer.writerow(result.columns_names())
                while result:
                    writer.writerows([row.as_list() for row in result])
                    if result.has_more_pages():
                        statement.set_page_state(result.page_state())
                        result = await self.session.execute(statement)
                    else:
                        break


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Acsylla cqlsh example.")
    parser.add_argument(
        "contact_points", nargs="*", default=["127.0.0.1"], help="Set contact points, default: 127.0.0.1:9042"
    )
    parser.add_argument("-v", "--protocol-version", default=3, type=int)
    parser.add_argument("-u", "--username", help="Authenticate as user.")
    parser.add_argument("-p", "--password", help="Authenticate using password.")
    parser.add_argument("-k", "--keyspace", help="Authenticate to the given keyspace.")
    parser.add_argument(
        "-V",
        "--version",
        action="version",
        version=f"{Colors.BLUE}%(prog)s: {__version__}{Colors.RESET}{Colors.GREEN}acsylla: "
        f"{acsylla.version.__version__}",
    )
    parser.add_argument("--ssl", help="Use SSL.", default=False, type=bool, dest="ssl_enabled")

    cqlsh = AcsyllaCQLSH(parser.parse_args())
    if sys.stdin.isatty():
        asyncio.run(cqlsh.tty())
    else:
        asyncio.run(cqlsh.stdin())
