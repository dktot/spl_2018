# SIMPLICITY v1.2.0.2
Shell script to install a Lunex Masternode on a Linux server running Ubuntu 16.04. Use it on your own risk.

# Installation:
wget -q https://raw.githubusercontent.com/dktot/spl_2018/master/install_v1.2.0.2.sh && bash install_v1.2.0.2.sh
***
# Desktop wallet setup
After the MN is up and running, you need to configure the desktop wallet accordingly. Here are the steps for Windows Wallet

1.Open **simplicity Wallet.**

2.Go to RECEIVE and create a New Address: **MN1**

3.Send **20k** SPL to **MN1**

4.Wait for 15 confirmations.

5.Go to **Tools** -> "**Debug console - Console**"

6.Type the following command: **masternode outputs**

7.Go to Tools -> "**Open Masternode Configuration File**"

8. Add the following entry:
```
<alias> <address:port> <MN private key> <MN input TX ID> <TX index> <reward address>
```
* Alias: **MN1**
* Address: **VPS_IP:PORT**
* Privkey: **Masternode Private Key**
* TxHash: **First value from Step 6**
* Output index:  **Second value from Step 6**
* reward address:  **Basic wallet address in your windows wallet. or you can make another address**

9. Save and close the file.
10. Go to **Masternode Tab**. If you tab is not shown, please enable it from: **Settings - Options - Wallet - Show Masternodes Tab**
11. Click **Update status** to see your node. If it is not shown, close the wallet and start it again.
12. Select your MN and click **Start Alias** to start it.
***


## Usage:
```
simplicity getinfo #This command will show your masternode status
simplicity masternode status #This command will show your masternode status
simplicity getinfo
lunex-cli masternode status #This command will show your masternode status
```

Also, if you want to check/start/stop **Lunex** , run one of the following commands as **root**:

```
systemctl status simplicity #To check the service is running.
systemctl start simplicity #To start simplicity service.
systemctl stop simplicity #To stop simplicity service.
systemctl is-enabled simplicity #To check whetether simplicity service is enabled on boot or not.(if you want test, vps reboot and check auto start)
```
***

## Issues:
If your simplicity Wallet doesn't sync, go to **Tools -> Open Wallet Configuration File** and add the following entries:
```
addnode=
addnode=
addnode=
```

***
## Donations:  

Any donation is highly appreciated.  

**SPL**: 8SLT7RTfMpeZsUdM8vqdK3Y9FAAU2DRXyj

**ETH**: 0x9B71b37252Af1C095eDa44F21faD344EC9d902CC

**BTC**: 15scr1X3hWGvdB3i4J4LdDhKuFPZtGCuQ4

