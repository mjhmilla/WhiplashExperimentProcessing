2023/02/15 M.Millard

1. The names of the channels from the biopac system in the *.mat files have some errors: TRU_L and TRU_R (trapezius unten) should instead be named SCP_L and SCP_R (splenius capitus). The names of these channels were copied over from the 2022 data collection when we did measure line of action of the trapezius between the shoulder and the neck. This muscle is virtually not activated during the car's movements, and so, we moved the EMG sensors to the splenius capitus.


2. The mvc notes (for example participant01/mvc/2023_02_06_MVC_Protocol_01.csv) have an inconsistent, and at times confusing, naming convention:

1. MVC back: always means neck extension and is done first 
2. MVC left/right: should be MVC (pulling to the) right, and was done immediately after after MVC back.
3. MVC front: always means neck flexion, and is done 3rd.
4. MVC right/left: should be MVC (pulling to the) left, and was done last.

You can perform a sanity check by looking at the file numbers: they will increase from MVC back, MVC right, MVC front, finally to MVC back. 

2. It appears that the head accelerometer was never attached to the head: the onset is very similar to the car (in contrast to the May 2022 collection) and the normalized magnitude is nearly identical, like it was sitting in the car. I believe there is a good chance that this is my fault. Though I could have sworn that I attached the accelerometer for the first few participants, perhaps I forgot. If I then forgot when I showed the hiwi's how to do this task ... well then we would end up with the entire data set not having the accelerometer attached to the head.
