"""Pruebas de la normalización del payload que realiza Node-RED."""
import json


def normalize_payload(payload):
    """Equivalente en Python de la función «Normalizar payload SerIoT»."""
    if isinstance(payload, (bytes, bytearray)):
        payload = payload.decode("utf-8")
    if isinstance(payload, str):
        try:
            payload = json.loads(payload)
        except json.JSONDecodeError:
            pass
    if payload is None:
        payload = {}
    if not isinstance(payload, dict):
        payload = {"value": payload}
    return payload


def test_json_text():
    data = normalize_payload('{"voltaje": 121.5, "corriente": 5.2}')
    assert data == {"voltaje": 121.5, "corriente": 5.2}


def test_buffer_utf8():
    data = normalize_payload(b'{"energia": 12.34}')
    assert data["energia"] == 12.34


def test_texto_plano_se_conserva():
    data = normalize_payload("hola")
    assert data == {"value": "hola"}


def test_none_se_convierte_en_objeto_vacio():
    assert normalize_payload(None) == {}


def test_escalar_se_encapsula():
    assert normalize_payload(42) == {"value": 42}


def test_lista_se_encapsula():
    assert normalize_payload([1, 2, 3]) == {"value": [1, 2, 3]}


def test_payload_minimo_de_telemetria():
    data = normalize_payload(
        '{"voltaje":121.5,"corriente":5.2,"energia":12.34,"timestamp":"2026-11-20T15:30:00-05:00"}'
    )
    assert {"voltaje", "corriente", "energia", "timestamp"} <= data.keys()
    assert all(isinstance(data[k], (int, float)) for k in ("voltaje", "corriente", "energia"))
