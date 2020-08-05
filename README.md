# Certichain
Store the IPFS hash[for certificates] securely in blockchain
Running project starts on 31/05/2020

## How to use
git clone the branch TruffleReact branch

--- 
Note : Do not collapse any terminal

##### terminal1
```
    1.  npm install
    2.  truffle develop
```
##### terminal2
```terminal2
    1. truffle migrate --reset
```
##### go to metamask
##### switch to custom network and place the config you got from truffle develop command (most probably will run on 8545 or 7545)
##### import some accounts with their private key mentioned in truffle develop . To make it work remember to import the first account.

##### terminal3
```terminal3
    cd client 
    cd src
    npm start
```

will take you directly on the webpage of this react app
and will ask for transaction confirmation from metamask.111
