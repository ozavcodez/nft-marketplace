// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTMarketplace is ERC721 {
    address private _owner;
    uint256 public nextTokenId;

    struct Listing {
        address seller;
        uint256 price;
        bool isForSale;
    }

    // Mapping from token ID to its listing details
    mapping(uint256 => Listing) public listings;

    // Events for marketplace actions
    event TokenListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event TokenSold(uint256 indexed tokenId, address indexed buyer, uint256 price);
    event ListingRemoved(uint256 indexed tokenId);
    event PriceUpdated(uint256 indexed tokenId, uint256 newPrice);

    // Modifier to restrict function access to the contract owner
    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not the owner");
        _;
    }

    constructor() ERC721("NFTMarketplace", "NFTM") {
        _owner = msg.sender; 
        nextTokenId = 1; 
    }

   
    function mint(address to) external onlyOwner {
        uint256 tokenId = nextTokenId; 
        nextTokenId++;

        _safeMint(to, tokenId);
    }

    
    function listForSale(uint256 tokenId, uint256 price) external {
        require(ownerOf(tokenId) == msg.sender, "Not the token owner");
        require(price > 0, "Price must be greater than 0");

        listings[tokenId] = Listing({
            seller: msg.sender,
            price: price,
            isForSale: true
        });

        emit TokenListed(tokenId, msg.sender, price);
    }

    /**
     * @dev Buy an NFT that is listed for sale. Buyer sends ETH equivalent to the price.
     * @param tokenId ID of the token to buy.
     */
    function buy(uint256 tokenId) external payable  {
        Listing memory listedItem = listings[tokenId];

        require(listedItem.isForSale, "Token not for sale");
        require(msg.value >= listedItem.price, "Insufficient funds");

        listings[tokenId].isForSale = false;

        _transfer(listedItem.seller, msg.sender, tokenId);

        (bool sent, ) = payable(listedItem.seller).call{value: msg.value}("");
        require(sent, "Transfer failed");

        emit TokenSold(tokenId, msg.sender, listedItem.price);
    }

   
    function removeListing(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Not the token owner");
        require(listings[tokenId].isForSale, "Token is not listed for sale");

        delete listings[tokenId];

        emit ListingRemoved(tokenId);
    }

    /**
     * @dev Change the price of an NFT that is already listed for sale. Only the seller can update.
     * @param tokenId ID of the token to update price.
     * @param newPrice The new sale price in wei.
     */
    function updatePrice(uint256 tokenId, uint256 newPrice) external {
        require(ownerOf(tokenId) == msg.sender, "Not the token owner");
        require(listings[tokenId].isForSale, "Token not listed for sale");
        require(newPrice > 0, "Price must be greater than 0");

        listings[tokenId].price = newPrice;

        emit PriceUpdated(tokenId, newPrice);
    }

    
    function withdraw() external onlyOwner  {
        (bool sent, ) = payable(_owner).call{value: address(this).balance}("");
        require(sent, "Withdrawal failed");
    }

    function owner() public view returns (address) {
        return _owner;
    }

    
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        _owner = newOwner;
    }
}
