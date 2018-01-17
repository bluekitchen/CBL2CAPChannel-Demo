#  CBL2CAPChannel-Demo

Test code to use LE Data Channels for sending data as fast as possible, e.g., for firmware uploads.
The BKL2CAPClient class can be instantiated with a UUID or a Name Prefix plus a PSM once a suitable device is found.

## Dynamic PSM
On iOS, the PSM for an CBL2CAPChannel can only dynamically assigned. This is necessary, as we would need to reserve world-wide unique PSMs for all applications.

To connect to an LE Data Channel on iOS, it's therfore necessary to retrieve the PSM from the iOS device. The most common approach is to provide a GATT Service with a GATT Characteristic that allows to read the dynamically assigned PSM.

This demo was created to connect to an LE Data Channel on an embedded device with a fixed PSM and does not implement such a "get PSM" mechanism.
