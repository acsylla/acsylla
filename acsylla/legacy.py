"""Values written by acsylla 1.2.0 and older in a way other drivers and acsylla 2.0 read differently."""

from decimal import Decimal
from typing import Optional
from typing import Union

import re

# acsylla 1.2.0 and older wrote the text of a decimal in place of its unscaled varint, with the number of digits after
# the point as the scale
_LEGACY_DECIMAL = re.compile(rb"[+-]?[0-9]+(?:\.([0-9]+))?")


def decode_legacy_decimal(value: Union[Decimal, str, None]) -> Optional[Decimal]:
    """The decimal acsylla 1.2.0 and older meant to write, when it wrote `value`, None when `value` can not be one.

    acsylla 1.2.0 and older wrote the text of a decimal in place of its unscaled value: Decimal("1234.5678") went to the
    server as 90750775191054255.4936, cqlsh and other drivers show it so and acsylla 2.0 reads it so. `value` is what
    acsylla 2.0 reads, a Decimal, or its str() with native_types.

    Only a value known to be written by acsylla 1.2.0 or older may be passed: another value can look the same, 12594
    is also the text "12" with the scale 0.
    """
    if value is None:
        return None
    if isinstance(value, str):
        value = Decimal(value)
    if not value.is_finite():
        return None
    sign, digits, exponent = value.as_tuple()
    unscaled = int("".join(map(str, digits)))
    if sign:
        unscaled = -unscaled
    text = unscaled.to_bytes(((unscaled if unscaled >= 0 else ~unscaled).bit_length() + 8) // 8, "big", signed=True)
    match = _LEGACY_DECIMAL.fullmatch(text)
    if match is None or len(match.group(1) or b"") != -exponent:
        return None
    return Decimal(text.decode("ascii"))
