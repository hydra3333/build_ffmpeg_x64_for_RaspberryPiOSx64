echo #
echo ##################################################################################################
echo #
echo # If you have **NOT** already entered an authorisation key into GITHUB
echo # --------------------------------------------------------------------
echo #
echo # then you need to do this on linux :-
echo # https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent
echo #
echo cd ~/Desktop
echo ssh-keygen -t rsa -b 4096 -C "hydra3333@gmail.com"
echo #  accept the default location ~/.ssh/id_rsa
echo #  enter the github password
echo #  enter the github password again
echo #
echo # save the private key into Agent and permanently into the the Keychain
echo eval "$(ssh-agent -s)"
echo ssh-add    ~/.ssh/id_rsa
echo ssh-add -k ~/.ssh/id_rsa
echo #  enter the github password
echo #
echo #  Display then copy the contents of the ~/.ssh/id_rsa.pub
echo cat ~/.ssh/id_rsa.pub
echo cp -fv ~/.ssh/id_* ./
echo #
echo #  Copy that text in its entirety to your clipboard
echo #  Open this URL in a browser https://github.com/settings/keys
echo #  Choose Add the new RSA key and when prompted 
echo #  and enter your guthub password to save the public key into github
echo #
echo #  You may wish to save the 2 keyfiles
echo #     ~/.ssh/id_*
echo #  by transferring them to your Windows PC saved software folders
echo #
echo #
echo ##################################################################################################
echo #
echo # If you HAVE already entered an authorisation key into GITHUB
echo # ------------------------------------------------------------
echo #
echo #  Copy the 2 saved keyfiles 
echo #     id_*
echo #  from the Windows saved software folders 
echo #  into the linux device in filder ~/Desktop
echo #
echo # then you need to do this on linux :-
echo #
echo cd ~/Desktop
echo #
echo #  copy the keyfils in to ~/.ssh
echo mkdir ~/.ssh
echo cp -fv ./id_* ~/.ssh/
echo #
echo # save the private key into Agent and permanently into the the Keychain
echo eval "$(ssh-agent -s)"
echo ssh-add    ~/.ssh/id_rsa
echo ssh-add -k ~/.ssh/id_rsa
echo #  enter the github password
echo #
echo ##################################################################################################
echo #
echo # You are now authorised by Github to do things like this :
echo #
echo git remote remove ffmpeg-upstream
echo git remote add ffmpeg-upstream git@github.com:FFmpeg/FFmpeg.git
echo git fetch ffmpeg-upstream
echo #git diff --patch ffmpeg-upstream/master master
echo git diff --patch ffmpeg-upstream/master master --output=../diff-updated-v4l2m2m-options.patch
echo cp -fv ./diff-updated-v4l2m2m-options.patch ~/Desktop/
echo cat ../diff-updated-v4l2m2m-options.patch
echo #
echo ##################################################################################################
echo #
