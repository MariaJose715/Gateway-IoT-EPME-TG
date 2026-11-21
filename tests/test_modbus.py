"""Pruebas de decodificación de registros Modbus FLOAT-32 del medidor Eastron."""
import struct


def decode_float32(registers, word_order="big"):
    """Decodifica dos registros de 16 bits como un FLOAT-32 IEEE 754.

    Args:
        registers: secuencia de dos enteros (0..65535).
        word_order: "big" si la palabra alta va primero; "little" si va después.
    """
    if len(registers) != 2:
        raise ValueError("Se esperaban exactamente dos registros")
    hi, lo = registers
    raw = hi.to_bytes(2, "big") + lo.to_bytes(2, "big")
    if word_order == "little":
        raw = raw[2:] + raw[:2]
    return struct.unpack(">f", raw)[0]


def test_tension_l1():
    assert decode_float32((0x42F3, 0x0000)) == 121.5


def test_corriente_l1():
    assert abs(decode_float32((0x40A6, 0x6666)) - 5.2) < 1e-5


def test_energia_importada():
    assert abs(decode_float32((0x4145, 0x70A4)) - 12.34) < 1e-5


def test_potencia_activa():
    assert decode_float32((0x441D, 0xC000)) == 631.0


def test_frecuencia():
    assert decode_float32((0x4270, 0x0000)) == 60.0


def test_orden_de_palabras_invertido():
    # El mismo valor con la palabra baja primero.
    assert decode_float32((0x0000, 0x42F3), word_order="little") == 121.5


def test_numero_de_registros_invalido():
    try:
        decode_float32((0x42F3,))
    except ValueError as exc:
        assert "dos registros" in str(exc)
    else:
        raise AssertionError("Se esperaba ValueError")
