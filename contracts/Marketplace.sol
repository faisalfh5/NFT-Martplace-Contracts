//SPDX-License-Identifier: Unlicense 
pragma solidity >= 0.4.22 <0.9.0;
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTMarketplace is ERC721URIStorage {
    using Counters for Counters.Counter;
    //_tokenIds variable has the most recent minted tokenId
    Counters.Counter private _tokenIds;
    //Keeps track of the number of items sold on the marketplace
    Counters.Counter private _itemsSold;
    //owner is the contract address that created the smart contract
    address payable owner;
    //The fee charged by the marketplace to be allowed to list an NFT
    uint256 public listPrice = 0.01 ether;
    //The structure to store info about a listed token
    struct ListedToken {
        uint256 tokenId;
        string name;
        string shortDes;
        address payable owner;
        address payable seller;
        address payable royal;
        uint256 price;
        uint8 royaltyPercentage;
        bool currentlyListed;
    }
    //the event emitted when a token is successfully listed
    event TokenListedSuccess(
        uint256 indexed tokenId,
        string name,
        string shortDes,
        address owner,
        address seller,
        address royal,
        uint256 price,
        uint256 royaltyPercentage,
        bool currentlyListed
    );
    //This mapping maps tokenId to token info and is helpful when retrieving details about a tokenId
    mapping(uint256 => ListedToken) private idToListedToken;
    // bidValue[] public myBid;
    constructor() ERC721("NFTMarketplace", "Comic Book") {
        owner = payable(msg.sender);
    }

    modifier isOwner(uint256 _tokenId) {
        require(idToListedToken[_tokenId].seller == msg.sender, "Only owner can update listing price");
        _;
    }

    function updateNFTPrice(uint256 _tokenId, uint256 _updatePrice) isOwner(_tokenId) public payable {
        idToListedToken[_tokenId].price = _updatePrice;
    }
   
    function getLatestIdToListedToken()
        public
        view
        returns (ListedToken memory)
    {
        uint256 currentTokenId = _tokenIds.current();
        return idToListedToken[currentTokenId];
    }
    function getListedTokenForId(
        uint256 tokenId
    ) public view returns (ListedToken memory) {
        return idToListedToken[tokenId];
    }
    function getCurrentToken() public view returns (uint256) {
        return _tokenIds.current();
    }
    //The first time a token is created, it is listed here
    function createToken(
        string memory _name,
        string memory _shortDes,
        string memory tokenPath,
        uint256 price,
        uint8 _royaltyPercentage
    ) public payable {
        //Increment the tokenId counter, which is keeping track of the number of minted NFTs
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        //Mint the NFT with tokenId newTokenId to the address who called createToken
        _safeMint(msg.sender, newTokenId);
        //Map the tokenId to the tokenURI
        _setTokenURI(newTokenId, tokenPath);
        //Helper function to update Global variables and emit an event
        createListedToken(newTokenId,_name, _shortDes, price, _royaltyPercentage);
    }
    
    function createListedToken(uint256 tokenId, string memory _name , string memory _shortDes,  uint256 price, uint8 _royaltyPercentage) private {
        //Make sure the sender sent enough ETH to pay for listing
        require(msg.value == listPrice , "Must your listing price equal to listPrice");
        console.log("listPrice", listPrice);
        //Just sanity check
        require(price > 0, "Make sure the price isn't negative");
        //Update the mapping of tokenId's to Token details, useful for retrieval functions
        idToListedToken[tokenId] = ListedToken(
            tokenId,
            _name,
            _shortDes,
            payable(address(this)),
            payable(msg.sender),
            payable(msg.sender),
            price,
            _royaltyPercentage,
            true
        );
        //Emit the event for successful transfer. The frontend parses this message and updates the end user
        emit TokenListedSuccess(
            tokenId,
            _name,
            _shortDes,
            address(this),
            msg.sender,
            msg.sender,
            price,
            _royaltyPercentage,
            true
        );
        payable(owner).transfer(listPrice);
    }
    //This will return all the NFTs currently listed to be sold on the marketplace
    function getAllNFTs() public view returns (ListedToken[] memory) {
        uint nftCount = _tokenIds.current();
        ListedToken[] memory tokens = new ListedToken[](nftCount);
        uint currentIndex = 0;
        uint currentId;
        //at the moment currentlyListed is true for all, if it becomes false in the future we will
        //filter out currentlyListed == false over here
        for (uint i = 0; i < nftCount; i++) {
            currentId = i + 1;
            ListedToken storage currentItem = idToListedToken[currentId];
            tokens[currentIndex] = currentItem;
            currentIndex += 1;
        }
        //the array 'tokens' has the list of all NFTs in the marketplace
        return tokens;
    }
    //Returns all the NFTs that the current user is owner or seller in
    function getMyNFTs() public view returns (ListedToken[] memory) {
        uint totalItemCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;
        uint currentId;
        //Important to get a count of all the NFTs that belong to the user before we can make an array for them
        for (uint i = 0; i < totalItemCount; i++) {
            if (
                idToListedToken[i + 1].owner == msg.sender ||
                idToListedToken[i + 1].seller == msg.sender
            ) {
                itemCount += 1;
            }
        }
        //Once you have the count of relevant NFTs, create an array then store all the NFTs in it
        ListedToken[] memory items = new ListedToken[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
            if (
                idToListedToken[i + 1].owner == msg.sender ||
                idToListedToken[i + 1].seller == msg.sender
            ) {
                currentId = i + 1;
                ListedToken storage currentItem = idToListedToken[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function executeSale(
        uint256 tokenId,
        address _buyerAccount,
        uint _royaltyAmmount
    ) public payable {
        uint price = idToListedToken[tokenId].price;
        address seller = idToListedToken[tokenId].seller;
        // Marketplace owner get the listing fee in every sale
        require(_buyerAccount.balance >= price && msg.value == price , "You don't have enough money to buy this NFT");
        //Transfer the proceeds from the sale to the seller of the NFT
        payable(seller).transfer(price);
        payable(idToListedToken[tokenId].royal).transfer(_royaltyAmmount);
        saleNFT(seller , _buyerAccount, tokenId );
    }

    function saleNFT(address seller,address _account, uint256 tokenId ) private {
        //update the details of the token
        idToListedToken[tokenId].currentlyListed = true;
        idToListedToken[tokenId].seller = payable(_account);
        _itemsSold.increment();
        //Actually transfer the token to the new owner
        _transfer(seller, _account, tokenId);
        //approve the marketplace to sell NFTs on your behalf
        approve(seller, tokenId);
    }

    struct Bid{
        address[] bidder;
        uint[] price;
    }
    mapping (uint => Bid) bidmapping ;


    function placeBid (uint _tokenid, uint _price) public {
    Bid storage bidding = bidmapping[_tokenid];
    for (uint i = 0; i < bidding.bidder.length; i++) {
        if (bidding.bidder[i] == msg.sender) {
            bidding.price[i] = _price;
            return;
        }
    }
    bidding.bidder.push(msg.sender);
    bidding.price.push(_price);
}


   function getBidders(uint256 _tokenid) public view returns (address[] memory bidder , uint[] memory price ) {
    return (bidmapping[_tokenid].bidder, bidmapping[_tokenid].price);
   }

    function AccpetBid(
        address buyer,
        uint tokenId,
        uint bidprice,
        uint _royaltyAmmount
    ) public payable {
        uint price = idToListedToken[tokenId].price;

    require(bidprice > price, "Your bid price is lower than actual price" );
    idToListedToken[tokenId].price = bidprice;
    executeSale(tokenId,buyer,_royaltyAmmount );

        // // uint price = idToListedToken[tokenId].price;
        // address seller = idToListedToken[tokenId].seller;
        // // require(msg.value == price , "You have enough meney to buy this NFT");
        // //update the details of the token
        // idToListedToken[tokenId].currentlyListed = true;
        // idToListedToken[tokenId].seller = payable(buyer);
        // _itemsSold.increment();
        // //Actually transfer the token to the new owner
        // _transfer(address(this), buyer, tokenId);
        // //Transfer the listing fee to the marketplace creator
        // payable(owner).transfer(listPrice);
        // //Transfer the proceeds from the sale to the seller of the NFT
        // payable(seller).transfer(bidprice);
        // // transfer new user ownership to contractr address
        // _transfer(buyer, address(this), tokenId);
    }
}