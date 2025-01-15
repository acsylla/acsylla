#include <cstring>
#include <mutex>
#include <queue>
#include <unistd.h>
#include <iostream>
#include <memory>

#include "cassandra.h"

class PosixToPython {
    public:
        PosixToPython(int write_fd);
        ~PosixToPython() = default;
        int write_fd;
        std::mutex _queue_mutex;
        std::queue<void *> _queue;
};

PosixToPython::PosixToPython(int fd) {
    write_fd = fd;
}

class CallbackContainer {
    public:
        CallbackContainer(PosixToPython* h, void* d);
        ~CallbackContainer() = default;
        PosixToPython* handler;
        void* data;
};

CallbackContainer::CallbackContainer(PosixToPython* h, void* d) {
    handler = h;
    data = d;
}

void posix_to_python_callback(CassFuture* cass_future, void* data){
    CallbackContainer* container = (CallbackContainer*)data;
    {
        std::lock_guard<std::mutex> lock(container->handler->_queue_mutex);
        container->handler->_queue.push(container->data);
    }
    (void *)write(container->handler->write_fd, "1", 1);
    delete container;
}


class PosixToPythonLogger {
    public:
        PosixToPythonLogger(int write_fd);
        ~PosixToPythonLogger() = default;
        int write_fd;
        std::mutex _queue_mutex;
        std::queue<std::shared_ptr<CassLogMessage>> _queue;
};

PosixToPythonLogger::PosixToPythonLogger(int fd) {
    write_fd = fd;
}

std::shared_ptr<CassLogMessage> copy_log_message(const CassLogMessage* message) {
    std::shared_ptr<CassLogMessage> message_copy = std::make_shared<CassLogMessage>();
    message_copy->time_ms = message->time_ms;
    message_copy->severity = message->severity;
    message_copy->line = message->line;
    message_copy->file = strdup(message->file);
    message_copy->function = strdup(message->function);
    std::memcpy(message_copy->message, message->message, CASS_LOG_MAX_MESSAGE_SIZE);

    return message_copy;
}

void posix_to_python_logger_callback(const CassLogMessage* message, void* data){
    PosixToPythonLogger* handler = (PosixToPythonLogger*)data;
    {
        std::lock_guard<std::mutex> lock(handler->_queue_mutex);
        std::shared_ptr<CassLogMessage> message_copy = copy_log_message(message);
        handler->_queue.push(message_copy);
    }
    (void *)write(handler->write_fd, "1", 1);
}