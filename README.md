# Server setup

The setup script will install required packages, configure security settings, and prepare your system for server deployment. 

open the terminal by pressing "Ctrl+Alt+T" once logged on with your user. 

Run the wget command to download the setup file.

    $ wget https://raw.githubusercontent.com/Hannes-Soosaar/vi/refs/heads/master/setup_vi.sh

Once the download completes allow execution for the script by in the terminal window by running the chmod command . (makes the script executable)

    $ chmod +x setup_vi.sh
 
Run the setup script (setup_vi.sh) in the terminal window.

    $ ./setup_vi.sh

- The setup will update and upgrade your system this might take a while depending on you configuration and internet speed.
- If you are using ssh to run the script you will be prompted to confirm you want to enable ufw as not to get locked out.

## Errors

If there are any during the setup process please send the log files

- **error_log.txt**
- **ufw_rules.txt**
- **installed_packages.txt**
- **ssh_status.txt**

 to: hsoosaar@gmail.com

 ## Help

 If you have any questions or are running into any issues please contact Hannes via email  hsoosaar@gmail.com for further instructions.