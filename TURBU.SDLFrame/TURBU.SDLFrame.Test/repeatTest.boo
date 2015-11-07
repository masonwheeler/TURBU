import TURBU.Meta

def repeatTest():
   i = 0
   repeat:
      print i
      ++i
      until i >= 3

def repeatTest2():
   x = 5
   repeat :
      ++x
      until x == 8         
      
def whileTest():
   i = 0
   while i < 5:
      ++i
   then: print "done"