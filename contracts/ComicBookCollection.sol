//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721.sol";
import "hardhat/console.sol";

contract ComicBookCollection {
    ERC721Template public nftTemp;

    struct CollectionsbyOwner {
        address[] nftcollections;
    }

    // mapping(address =>  address) public CollectionRecords;
    // owner address to collection
    mapping(address => CollectionsbyOwner) CollectionOwner;

    modifier isOwner(address _nftCollection) {
        CollectionsbyOwner memory Data = CollectionOwner[msg.sender];
        for(uint i=0; i < Data.nftcollections.length; i++){
            uint dataLength = Data.nftcollections.length;
            if(Data.nftcollections[i] != _nftCollection && dataLength == 0 ){
            revert("You are not the owner");    
            }
        }
        _;
    }

    function createCollection(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 _totalSupply,
        uint256 _mintPrice,
        uint256 _startDate,
        uint256 _expirationDate
    ) public {
        nftTemp = new ERC721Template(_name,_symbol, _uri, _totalSupply, _mintPrice, _startDate, _expirationDate);
        console.log("nftTemp Address", address(nftTemp));
        CollectionsbyOwner storage tempCollections =  CollectionOwner[msg.sender];
        tempCollections.nftcollections.push(address(nftTemp));
        transferOwner(payable (msg.sender), address(nftTemp));
    }

    function transferOwner(address payable newOwner, address _nftCollection)
        internal
    {
        nftTemp = getCollectionInstance(_nftCollection);
        nftTemp.setOwner(newOwner);
        nftTemp.transferOwnership(newOwner);
    }

    function BuyCollection(address _collectionAddress) public payable  {
        nftTemp = getCollectionInstance(_collectionAddress);
        require( msg.sender.balance >= nftTemp.mintPrice() && msg.value == nftTemp.mintPrice(), "You don't have enough balance to buy");
        payable(nftTemp.Owner()).transfer(nftTemp.mintPrice());
        CollectionsbyOwner storage tempCollections =  CollectionOwner[msg.sender];
        tempCollections.nftcollections.push(_collectionAddress);
        transferOwner(payable (msg.sender) , _collectionAddress);
    }

    function updateUri(string memory _newUri, address _nftCollection)
        public
        isOwner(_nftCollection)
    {
        nftTemp = getCollectionInstance(_nftCollection);
         nftTemp.setBaseURI(_newUri);
    }

    function updatePrice(uint256 _newPrice, address _nftCollection)
        public isOwner(_nftCollection)
    {
        nftTemp = getCollectionInstance(_nftCollection);
        nftTemp.updatePrice(_newPrice);
    }

    
    function getCollections(address _owner) public view returns(CollectionsbyOwner memory){
        return CollectionOwner[_owner];
    }

    function _getCollectionData(address _nftCollection) public isOwner(_nftCollection) returns(uint256 _mintPrice, 
    uint256 _startDate, uint256 _expirationDate){
        nftTemp = ERC721Template(_nftCollection);
        return( nftTemp.mintPrice(),nftTemp.startDate() ,nftTemp.expirationDate());
    }

    function getCollectionInstance(address _nftCollection) internal pure virtual returns (ERC721Template) {
        return ERC721Template(_nftCollection);
    }

}