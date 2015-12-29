// Generated by CoffeeScript 1.10.0
(function() {
  this.Vector = (function() {
    function Vector(a1) {
      this.a = a1;
      this.string = (this.a[0].toFixed(4)) + ", " + (this.a[1].toFixed(4)) + ", " + (this.a[2].toFixed(4));
    }

    Vector.prototype.array = function() {
      return new Float32Array(this.a);
    };

    Vector.prototype.elements = function() {
      return this.a;
    };

    Vector.prototype.normalize = function() {
      var rlf;
      rlf = 1 / Math.sqrt(this.a[0] * this.a[0] + this.a[1] * this.a[1] + this.a[2] * this.a[2]);
      return new Vector([this.a[0] * rlf, this.a[1] * rlf, this.a[2] * rlf]);
    };

    Vector.prototype.crossProduct = function(v) {
      var b, x, y, z;
      b = v.elements();
      x = this.a[1] * b[2] - this.a[2] * b[1];
      y = this.a[2] * b[0] - this.a[0] * b[2];
      z = this.a[0] * b[1] - this.a[1] * b[0];
      return new Vector([x, y, z]);
    };

    Vector.prototype.dotProduct = function(v) {
      var i;
      return ((function() {
        var j, results;
        results = [];
        for (i = j = 0; j <= 2; i = ++j) {
          results.push(this.a[i] * v.a[i]);
        }
        return results;
      }).call(this)).reduce(function(p, c, i, a) {
        return p + c;
      });
    };

    Vector.prototype.minus = function(v) {
      var b;
      b = v.elements();
      return new Vector([this.a[0] - b[0], this.a[1] - b[1], this.a[2] - b[2]]);
    };

    Vector.prototype.add = function(v) {
      var b;
      b = v.elements();
      return new Vector([this.a[0] + b[0], this.a[1] + b[1], this.a[2] + b[2]]);
    };

    Vector.nor = function(a, b) {
      return [+(!(a[0] || b[0])), +(!(a[1] || b[1])), +(!(a[2] || b[2]))];
    };

    Vector.g = function() {
      return ((Math.random() + Math.random() + Math.random() + Math.random() + Math.random() + Math.random()) - 3) / 3;
    };

    Vector.gauss = function() {
      return new Vector([this.g(), this.g(), this.g()]).normalize();
    };

    Vector.random = function() {
      return new Vector([Math.random() * 2 - 1, Math.random() * 2 - 1, Math.random() * 2 - 1]).normalize();
    };

    Vector.lerp = function(a, b, t) {
      return new Vector([a.a[0] + (b.a[0] - a.a[0]) * t, a.a[1] + (b.a[1] - a.a[1]) * t, a.a[2] + (b.a[2] - a.a[2]) * t]);
    };

    Vector.slerp = function(a, b, t) {
      var o;
      o = Math.acos(a.dotProduct(b));
      return a.scale(Math.sin((1 - t) * o) / Math.sin(o)).add(b.scale(Math.sin(t * o) / Math.sin(o)));
    };

    Vector.prototype.distance = function(v) {
      return Math.sqrt(Math.pow(v.a[0] - this.a[0], 2) + Math.pow(v.a[1] - this.a[1], 2) + Math.pow(v.a[2] - this.a[2], 2));
    };

    Vector.prototype.scale = function(n) {
      return new Vector([this.a[0] * n, this.a[1] * n, this.a[2] * n]);
    };

    Vector.prototype.cols = function() {
      return [[this.a[0], this.a[1], this.a[2], 1]];
    };

    Vector.prototype.toString = function() {
      return this.string;
    };

    return Vector;

  })();

}).call(this);

//# sourceMappingURL=vector.js.map
