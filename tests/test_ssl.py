from acsylla import create_cluster, SSLVerifyFlags

import acsylla.errors
import pytest

pytestmark = pytest.mark.asyncio


class TestSSL:
    async def test_ssl_no_cert(self, host):
        create_cluster([host], ssl_enabled=True)

    async def test_ssl(self, host, certificates):
        ssl_cert, ssl_private_key, ssl_trusted_cert = certificates
        cluster = create_cluster(
            [host],
            ssl_enabled=True,
            ssl_cert=ssl_cert,
            ssl_private_key=ssl_private_key,
            ssl_trusted_cert=ssl_trusted_cert,
        )
        await cluster.create_session()

    async def test_ssl_flags_none(self, host, certificates):
        ssl_cert, ssl_private_key, ssl_trusted_cert = certificates
        cluster = create_cluster(
            [host],
            ssl_enabled=True,
            ssl_cert=ssl_cert,
            ssl_private_key=ssl_private_key,
            ssl_verify_flags=SSLVerifyFlags.NONE,
        )
        await cluster.create_session()

    async def test_ssl_flags_peer_cert(self, host, certificates):
        ssl_cert, ssl_private_key, ssl_trusted_cert = certificates
        cluster = create_cluster(
            [host],
            ssl_enabled=True,
            ssl_cert=ssl_cert,
            ssl_private_key=ssl_private_key,
            ssl_verify_flags=SSLVerifyFlags.PEER_CERT,
        )
        with pytest.raises(acsylla.errors.CassErrorSslInvalidPeerCert):
            await cluster.create_session()

    async def test_ssl_flags_peer_identity(self, host, certificates):
        ssl_cert, ssl_private_key, ssl_trusted_cert = certificates
        cluster = create_cluster(
            [host],
            ssl_enabled=True,
            ssl_cert=ssl_cert,
            ssl_private_key=ssl_private_key,
            ssl_trusted_cert=ssl_trusted_cert,
            ssl_verify_flags=SSLVerifyFlags.PEER_IDENTITY,
        )
        await cluster.create_session()

    async def test_ssl_flags_peer_identity_dns(self, host, certificates):
        ssl_cert, ssl_private_key, ssl_trusted_cert = certificates
        cluster = create_cluster(
            [host],
            ssl_enabled=True,
            ssl_cert=ssl_cert,
            ssl_private_key=ssl_private_key,
            ssl_trusted_cert=ssl_trusted_cert,
            ssl_verify_flags=SSLVerifyFlags.PEER_IDENTITY_DNS,
        )
        await cluster.create_session()
