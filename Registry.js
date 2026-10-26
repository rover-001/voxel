.pragma library

var _instance = null;

function set(inst) {
  _instance = inst;
}

function get() {
  return _instance;
}
