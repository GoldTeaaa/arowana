-include .env

NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(ANVIL_KEY_1) --broadcast

deploy:
	@forge script script/DeployNFT.s.sol:DeployToken $(NETWORK_ARGS)

mintNft:
	@cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 "mint(string, string, string, string)" https://bafybeihdgawpw5r3lvb7gbgceba7n3jniv7253bjcukzhdowqt5sw5ly3i.ipfs.dweb.link?filename=SuperRed-1.m.JSON, RfidTest2, mom123.2, dad123.2 --private-key $(ANVIL_KEY_1) --rpc-url "http://localhost:8545"