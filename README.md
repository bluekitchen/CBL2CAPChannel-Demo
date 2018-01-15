#  CBL2CAPChannel-Demo

Test code to use LE Data Channels for sending data as fast as possible, e.g., for firmware uploads.
The BKL2CAPClient class can be instantiated with a UUID or a Name Prefix plus a PSM once a suitable device is found.

## Status
After connect, about 20kB are buffered locally. Then after sending another 180 kB, the connection drops with an error. Tested on iPhone 6S with iOS 11.1.2.


