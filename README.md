# onx-lending-contract

## Prerequestis

1. Install hardhat environment.
2. Setup key, network info. Copy `keys.json.example` to `keys.json` and add proper values.

```
npm install
```

## How to compile?

```
npm run compile
```

or

```
npx hardhat compile
```


## How to test?

```
npm run test
```

or

```
npx hardhat test
```


## How to deploy?

```
npx hardhat run --network ropsten deploy/deploy.js
```

or

```
npx hardhat deploy-ropsten
```
