function rm = convertQuaternionToRotationMatrix(x,y,z,w)

w2 = w*w;
x2 = x*x;
y2 = y*y;
z2 = z*z;

assert( abs(w2 + x2 + y2 + z2 - 1) < eps*100,...
        'Error: quaternion norm must be 1 to use this function');

rm = [(1-2*(y2+z2)),    2*(x*y-w*z),   2*(w*y+x*z);...
        2*(x*y+w*z),  (1-2*(x2+z2)),   2*(y*z-w*x);...
       2*(-w*y+x*z),    2*(y*z+w*x), (1-2*(x2+y2))];