## state variables

c => percentageCut
p => basePrice
b => buyId
l => listId
m => metaUrl
bp => boughtPrices
sp => sellPrices
I => isSellings
bs => buyIds

## buy token
B => EventBuyToken
b => buyId
x => lon
y => lat
T => buyer
F => seller
d => price
t => timestamp
id => tokenId

BN => EventBuyTokenNearby
id1 => tokenId1
x => lon
y => lat
T => buyer
F => seller
d => price
t => timestamp

## list token
L => EventListToken
l => listId
b => buyId
x => lon
y => lat
F => seller
d => price
il => isListed
t => timestamp
id => tokenId

LN => EventListToken
l => listId
b => buyId
id1 => tokenId1
x => lon
y => lat
F => seller
d => price
il => isListed
t => timestamp

## receive approval
R => EventReceiveApproval
T => buyer
s => coins
a => _coinAddress
d => _data




