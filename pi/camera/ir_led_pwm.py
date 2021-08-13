import RPi.GPIO as GPIO
import time

ledpin = 12				        # PWM pin connected to LED
freq = 1000
led_intensity = 30              # % 
GPIO.setmode(GPIO.BOARD)		# set pin numbering system
GPIO.setup(ledpin,GPIO.OUT)
pi_pwm = GPIO.PWM(ledpin,freq)	# create PWM instance with frequency
pi_pwm.start(0)				    # start PWM of required Duty Cycle 
pi_pwm.ChangeDutyCycle(led_intensity)

try:                            # keep program running to keep pwm alive
    while 1:
        time.sleep(0.5)
except KeyboardInterrupt:
    pass
GPIO.cleanup()