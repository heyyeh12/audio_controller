#!usr/bin/env python  
#coding=utf-8  

import pyaudio  
import wave 
import sys

#define stream chunk   
chunk = 1  

#open a wav format music 
try:
	f = wave.open(sys.argv[1], 'rb')
	fp = open(sys.argv[1].split(".")[0]+'.txt', 'wb+')
except:
	f = wave.open(r'hihat-808.wav','rb')
	fp = open('hihat_808.txt', 'wb+')    
p = pyaudio.PyAudio()

#open stream  
stream = p.open(format = p.get_format_from_width(f.getsampwidth()),  
                channels = f.getnchannels(),  
                rate = f.getframerate(),  
                output = True)  
#read data  
data = f.readframes(chunk)  

#paly stream  
while len(data) > 0:
    stream.write(data)
    # offset so 32 bits (NOTE: little endian, MSB is 0 bit)
    fp.write(bytes([0])) 
    fp.write(data)
    data = f.readframes(chunk)

#stop stream  
stream.stop_stream()  
stream.close()  

#close PyAudio  
p.terminate() 