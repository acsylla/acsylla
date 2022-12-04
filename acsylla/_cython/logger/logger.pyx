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
        'disabled': None,
        'critical': logging.CRITICAL,
        'error': logging.ERROR,
        'warn': logging.WARNING,
        'warning': logging.WARNING,
        'info': logging.INFO,
        'debug': logging.DEBUG,
        'trace': logging.DEBUG
    }
    _instances = {}

    @classmethod
    def instance(cls, *args, **kwargs):
        if cls not in cls._instances:
            cls._instances[cls] = None
            cls._instances[cls] = cls(*args, **kwargs)
        return cls._instances[cls]

    def __cinit__(self):
        if not self._instances:
            raise RuntimeError('Use Logger.instance() for initializing Logger')
        self.log = self._log_fn
        cass_log_set_callback(cb_log_message, <void*>self)

    def __init__(self, log_level='warn', logging_callback=None):
        self.set_log_level(log_level)
        self.logging_callback = logging_callback

    def set_log_level(self, level):
        if level is not None:
            try:
                cass_log_set_level(log_level_from_str(level))
            except KeyError:
                raise ValueError(f'Unknown log_level "{level}". '
                                 f'Log level must be one of ({", ".join(self.levels.keys())})')
            log_level = self.levels[level.lower()]
            if log_level is not None:
                logger.setLevel(log_level)

    def set_logging_callback(self, callback):
        self.logging_callback = callback

    def get_logger(self):
        return logger

    def _log_fn(self, msg):
        if self.logging_callback is not None:
            self.logging_callback(msg)
        else:
            self.logger_fn[msg.log_level](msg.message)
