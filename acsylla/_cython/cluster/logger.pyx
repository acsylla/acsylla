import logging

logger = logging.getLogger('acsylla')

cdef log_level_from_str(object level):
    levels = {
        'disabled': CASS_LOG_DISABLED,
        'critical': CASS_LOG_CRITICAL,
        'error': CASS_LOG_ERROR,
        'warn': CASS_LOG_WARN,
        'warning': CASS_LOG_WARN,
        'info': CASS_LOG_INFO,
        'debug': CASS_LOG_DEBUG,
        'trace': CASS_LOG_TRACE,
    }
    return levels[level.lower()]


cdef class Logger:
    logger_fn = {
        'CRITICAL': logger.critical,
        'ERROR': logger.error,
        'WARN': logger.warning,
        'INFO': logger.info,
        'DEBUG': logger.debug,
        'TRACE': logger.debug
    }
    levels = {
        'DISABLED': None,
        'CRITICAL': logging.CRITICAL,
        'ERROR': logging.ERROR,
        'WARN': logging.WARNING,
        'INFO': logging.INFO,
        'DEBUG': logging.DEBUG,
        'TRACE': logging.DEBUG
    }
    def __init__(self, log_level, logging_callback=None):
        self.logging_callback = logging_callback
        log_level = self.levels[log_level.upper()]
        self.log = self.log_fn
        if logging_callback is None and log_level is not None:
            logger.setLevel(log_level)

    def log_fn(self, msg):
        if self.logging_callback:
            self.logging_callback(msg)
        else:
            self.logger_fn[msg.log_level](msg.message)
