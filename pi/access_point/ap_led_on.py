import RPi.GPIO as GPIO
import time

ledpin = 21
GPIO.setmode(GPIO.BCM)
GPIO.setup(ledpin,GPIO.OUT)
GPIO.output(ledpin,GPIO.HIGH)
try:                            # keep program running to keep pwm alive
    while 1:
        time.sleep(0.5)
except KeyboardInterrupt:
    pass
GPIO.cleanup()