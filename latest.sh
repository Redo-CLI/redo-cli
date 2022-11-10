#! /bin/bash
INSTALLER_VERSION="1.0.1"
echo "Installer version: v"$INSTALLER_VERSION
echo "Installing redo..."
echo "Installing in: /usr/local/bin"
curl -s https://raw.githubusercontent.com/redo-cli/redo-cli/master/redo.sh > /tmp/redo.sh
mv /tmp/redo.sh /usr/local/bin/redo 2>/dev/null
chmod +x /usr/local/bin/redo 2>/dev/null
if [ -e "/usr/local/bin/redo" ]
then
	"Done!"
else
	sudo mv /tmp/redo.sh /usr/local/bin/redo 
	sudo chmod +x /usr/local/bin/redo
fi

echo "Installation complete."
echo "You are ready to do more without leaving the terminal!"