import logging

from rich.logging import RichHandler

_logger = None


def get_logger(
    name: str = __name__,
    level: int = logging.DEBUG,
    log_to_file: bool = False,
    file_name: str = "/var/log/my-app/app.log",
) -> logging.Logger:
    global _logger
    if _logger is None:
        _logger = logging.getLogger(name)

        if not _logger.hasHandlers():
            stream_handler = RichHandler()
            _logger.addHandler(stream_handler)

            if log_to_file:
                file_handler = logging.FileHandler(file_name)
                file_formatter = logging.Formatter(
                    "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
                )
                file_handler.setFormatter(file_formatter)
                _logger.addHandler(file_handler)

        _logger.setLevel(level)
    return _logger
