-include .env

NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(ANVIL_KEY_1) --broadcast

deploy:
	@forge script script/DeployNFT.s.sol:DeployToken $(NETWORK_ARGS)

mintNft:
	@cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 "mint(string, string, string, string)" https://gateway.pinata.cloud/ipfs/bafkreibxfzslz7cn7izmjtarmoj2hr52ukw7ri5bdpnpkjafvn4ouljckq, Bx6821xe68521, Bdca78e61273i, Bcsn087218e1 --private-key $(ANVIL_KEY_1) --rpc-url "http://localhost:8545"