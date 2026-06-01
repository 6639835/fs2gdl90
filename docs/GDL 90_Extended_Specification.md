# GDL 90 EXTENDED SPECIFICATION

ForeFlight offff ers the industry-standard GDL 90 Data Interface Specififi cation defifi ned below for third-party devices to transmit live inflfl ight data to ForeFlight Mobile. Properly confifi gured devices will be able to display ADS-B weather and traffiffi c, AHRS, device name information, and GPS data in the ForeFlight Mobile app. 

Please note: ForeFlight does not test or provide support for devices that use this specifi cation. If you experience problems with a device that uses this specifi cation, please contact the device manufacturer for assistance. 

# Connectivity

ForeFlight expects data sent using UDP to port 4000 on the iOS device. Implementers are strongly advised to use UDP unicast to avoid signifi cant packet loss, as iOS applications such as ForeFlight cannot reliably receive UDP broadcast messages, but perform much better with UDP unicast. See ForeFlight Broadcast below to learn how to discover ForeFlight's IP address 

to set as a UDP unicast target.We use fi rst-party and third-party tracking technologies, including cookies, pixels, chatbot services, and web beacons to enhance your experience, personalize content and ads, provide social media features, off er support, and analyze site metrics. For these purposes, information about your use of our sites is collected by or shared with our social media, chatbot, session replay, advertising, and analytics providers. Please accept or limit cookie all packets (including headers) smaller than 1500 bytes.preferences in this banner; note that strictly necessary cookies are always active. You may manage your cookie preferences at any time by clicking "Cookie Settings". By continuing to use our website, you agree that you have read and consent to the terms of our Privacy Policy 

Reject non-essential cookies 

Accept Cookies 

running in the foreground. This message allows implementers to discover ForeFlight's IP address, which can be used as the target of UDP unicast messages. This is especially helpful when the implementer and the iOS device are on a shared infrastructure Wi-Fi network; otherwise, the implementer cannot identify connected clients' IP addresses. 

This broadcast will be a JSON message, with at least these fi elds: 

```json
{
    "App":"ForeFlight",
    "GDL90":{
    "port":4000
    }
} 
```

The GDL90 "port" fi eld is currently 4000, but ForeFlight reserves the right to change this port number in the future as advanced confi guration on networks where there are collisions on port 4000. 

Implementors in certifi ed avionics (or otherwise diffi cult-to-update software installations) are advised to consider allowing ForeFlight's broadcast port (port 63093) to be modifi ed via advanced confi guration as well, in case of port collisions on certain networks. 

# Messages

The ForeFlight GDL90 Extension protocol defi nes messages based on the GDL90 protocol. Section 2.2 of the GDL90 specifi cation describes the message structure and Section 3 outlines a set of standard messages. ForeFlight supports a subset of the standard messages and also extends the protocol with a pair of custom messages containing device ID and AHRS information. 

# Heartbeat Message

See GDL90 specifi cation §3.1 for complete details. Only GPS validity bit is checked at this time. 

<table><tr><td>BYTE #</td><td>NAME</td><td>SIZE</td><td>VALUE</td></tr><tr><td>1</td><td>Message ID</td><td>1</td><td>010 = Heartbeat</td></tr><tr><td>2</td><td>Status Byte 1Bit 7: GPS Pos Valid</td><td>1</td><td>1 = Position is available for ADS-B TxOther bits are ignored</td></tr><tr><td>3</td><td>Status Byte 2</td><td>1</td><td>All bits ignored</td></tr><tr><td>4-5</td><td>Time Stamp</td><td>2</td><td>Ignored</td></tr><tr><td>6-7</td><td>Message Counts</td><td>2</td><td>Ignored</td></tr></table>

# UAT Uplink

See GDL90 specifi cation §3.3 for complete details. 

<table><tr><td>BYTE #</td><td>NAME</td><td>SIZE</td><td>VALUE</td></tr><tr><td>1</td><td>Message ID</td><td>1</td><td>710 = Uplink Data</td></tr><tr><td>2-4</td><td>Time of Reception</td><td>3</td><td>24-bit binary fractionResolution = 80 nsec</td></tr><tr><td>5-436</td><td>Uplink Payload</td><td>432</td><td>UAT Uplink Packet. See §3.3.2 for details</td></tr></table>

# Ownship Report

See GDL90 specifi cation §3.4 for complete details. The position information in this message is used by ForeFlight to determine current position. 

<table><tr><td>BYTE #</td><td>NAME</td><td>SIZE</td><td>VALUE</td></tr><tr><td>1</td><td>Message ID</td><td>1</td><td>1010 = Ownship Report</td></tr><tr><td>2-28</td><td>Ownship Report</td><td>27</td><td>Defined in §3.5.1</td></tr></table>

# Notes:

Accuracy information is encoded by setting the NACp value. 

Altitude is defi ned as ownship pressure altitude (referenced to 29.92 inches Hg). For unpressurized aircraft a barometer in the cabin is close enough for practical purposes, but in pressurized aircraft, care must be taken to set this fi eld to 0xFFF (Invalid or Unavailable) if the device does not have access to outside pressure. Setting ownship pressure altitude incorrectly will result in incorrect calculation of relative traffi c altitude. 

For implementations without access to an aircraft Participant Address (ICAO code) or callsign/tail number, the Participant Address should be set to 0x000000 or 0xF00000. This indicates the Ownship Report should be used for GPS telemetry only and enables independent ownship detection of received traffi c reports. 

# Ownship Geometric Altitude

See GDL90 specifi cation §3.8 for complete details. Note that the altitude may be interpreted as either relative to the WGS-84 ellipsoid as spec'ed, or to the WGS-84 geoid (MSL). The ID message described below defi nes how this altitude will be interpreted. 

<table><tr><td>BYTE #</td><td>NAME</td><td>SIZE</td><td>VALUE</td></tr><tr><td>1</td><td>Message ID</td><td>1</td><td>1110 = Ownship Geo Alt</td></tr><tr><td>2-3</td><td>Ownship Geo Altitude</td><td>2</td><td>Signed altitude in 5ft resolution.Byte 2 is the Most Significant ByteAltitude is interpreted as relative to the WGS84 ellipsoid unless Bit 0 of the ID Message Capabilities Mask is set, in which case it's treated as MSL.</td></tr><tr><td>4-5</td><td>Vertical Metrics</td><td>2</td><td>Vertical Warning Indicator (MSB of Byte 4)Vertical Figure of Merit (remaining 15 bits).0x7FFF indicates VFOM not available0x7EEE indicates VFOM is &gt;32766 metersByte 4 is the most significant byte.</td></tr></table>

# Traffic Report

See GDL90 specifi cation §3.5 for complete details. 

<table><tr><td>BYTE #</td><td>NAME</td><td>SIZE</td><td>VALUE</td></tr><tr><td>1</td><td>Message ID</td><td>1</td><td>2010 = Traffic Report</td></tr><tr><td>2-28</td><td>Traffic Report</td><td>27</td><td>Defined in §3.5.1</td></tr></table>

# ID Message

For multibyte fi elds, the most signifi cant byte should be sent fi rst (Big Endian). 

<table><tr><td>BYTE #</td><td>NAME</td><td>SIZE</td><td>VALUE</td></tr><tr><td>1</td><td>ForeFlight Message ID</td><td>1</td><td>0x65</td></tr><tr><td>2</td><td>ForeFlight Message sub-ID</td><td>1</td><td>0</td></tr><tr><td>3</td><td>Version</td><td>1</td><td>Must be 1</td></tr><tr><td>4-11</td><td>Device serial number</td><td>8</td><td>0xFFFFFFFFFFFFFFFF for invalid</td></tr><tr><td>12-19</td><td>Device name</td><td>8</td><td>8B UTF8 string.</td></tr><tr><td>20-35</td><td>Device long name</td><td>16</td><td>16B UTF8 string. Can be the same as Device name. Used when there is sufficient space for a longer string.</td></tr><tr><td>36-39</td><td>Capabilities mask</td><td>4</td><td>Bit 0 (LSB): Geometric altitude datum used in the GDL90 Ownship Geometric Altitudes message0: WGS-84 ellipsoid(as the GDL90 spec states)1: MSLBits 1,2 (LSB): Internet Policy - how ForeFlight will access the internet while connected to a Wireless Device.0: Unrestricted1: Expensive(reduced bandwidth usage)2: Disallowed (will not attempt to access the internet)Bits 3-31: Reserved. Should be all 0's.</td></tr></table>

# AHRS Message

For multibyte fi elds, the most signifi cant byte should be sent fi rst (Big Endian). 

<table><tr><td>BYTE #</td><td>NAME</td><td>SIZE</td><td>VALUE</td></tr><tr><td>1</td><td>ForeFlight Message ID</td><td>1</td><td>0x65</td></tr><tr><td>2</td><td>AHRS Sub-Message D</td><td>1</td><td>0x01</td></tr><tr><td>3-4</td><td>Roll</td><td>2</td><td>Roll in units of 1/10 degree0x7fff for invalid.Positive values indicate right wing down, negative values indicate right wing up.The message will be rejected if roll is outside of the range [-1800, 1800]</td></tr><tr><td>5-6</td><td>Pitch</td><td>2</td><td>Pitch in units of 1/10 degree0x7fff for invalid.Positive values indicate nose up, negative values indicate nose down.The message will be rejected if pitch is outside of the range [-1800, 1800]</td></tr><tr><td>7-8</td><td>Heading</td><td>2</td><td>Most significant bit (bit 15)0: True Heading1: Magnetic HeadingBits 14-0: Heading in units of 1/10 degreeTrack should NOT be used here.0xffff for invalid.The message will be rejected if heading is outside of the range [-3600,3600]</td></tr><tr><td>9-10</td><td>Indicated Airspeed</td><td>2</td><td>Value in Knots0xffff for invalid.</td></tr><tr><td>11-12</td><td>True Airspeed</td><td>2</td><td>Value in Knots0xffff for invalid.</td></tr></table>

# REGISTER FOR THE NEWSLETTER

Enter your email here. 

# SIGN-UP

# PRODUCTS

ForeFlight Mobile 

ForeFlight On The Web 

ForeFlight Dispatch 

Sentry ADS-B 

ForeFlight Directory 

Military Flight Bag 

ForeFlight Gift Certifi cates 

# SOLUTIONS

General Aviation 

Business Aviation 

Military 

Helicopter 

Education & Flight Training 

FBOs 

# RESOURCES

Resources Home 

Support Center 

Video Library 

Webinars 

Release History 

General Aviation Blog 

Business Aviation Blog 

Logbook 

International Support Lookup 

Synthetic Vision 

Trip Assistant 

JetFuelX 

Jeppesen 

Plans And Pricing 

Runway Analysis - Business 

# COMPANY

About ForeFlight 

Team 

Partners 

Careers 

Media Kit 

Privacy Policy 

Cookie Settings 

Security & Certifi cations 

Buy ForeFlight Gear 

# CONNECT WITH US

![](images/745d916f9e5dc49959c25e934b3a61d738e1195f5b9c3ba6188889866ff86980.jpg)


![](images/8e530cdb75dfdbedd52b0804a1b20c7dbb5ec8a5147a7de5eb2518aa80e9db3d.jpg)


![](images/69e688baeca01210528419f520bb6d0e03d7c66206410163fa1032eda1728734.jpg)


![](images/ab2e0fc48d27e83d7e4cc0efe6a2b159ef1dc8078be8a69dcbb35c9aeee4fa6b.jpg)


![](images/b7487dd6223cd305acc736a675d3a377d6e8ecfe5b70b09801ed085dad2df4ba.jpg)


Download on the 

App Store 

![](images/4f5059e9b483fe35464da46e6be4e349bc0feeb6334acc8e42f8d1f3d127abb1.jpg)
