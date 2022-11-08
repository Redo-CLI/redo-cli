#! /bin/bash
echo "Installing redo..."
echo "Installing in: /usr/local/bin"
curl -s https://raw.githubusercontent.com/redo-cli/redo-cli/master/redo.sh > /tmp/redo.sh
mv /tmp/redo.sh /usr/local/bin/redo
chmod +x /usr/local/bin/redo
echo "Installation complete."
echo "You are ready to do more without leaving the terminal!"