function rm = convertQuaternionToRotationMatrix(q0,q1,q2,q3)

q02 = q0*q0;
q12 = q1*q1;
q22 = q2*q2;
q32 = q3*q3;

rm = [(q02+q12-q22-q32),    2*(q1*q2-q0*q3),   2*(q0*q2-q1*q3);...
        2*(q1*q2+q0*q3),  (q02-q12+q22-q32),   2*(q2*q3-q0*q1);...
       2*(-q0*q2+q1*q3),    2*(q2*q3+q0*q1), (q02-q12-q22+q32)];