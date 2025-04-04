// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract Twitter {
    struct Tweet {
        uint id;
        address author;
        string content;
        uint createdAt;
    }
    struct Message {
        uint id;
        string content;
        address from;
        address to;
        uint createdAt;
    }
    mapping(uint => Tweet) public tweets;
    mapping(address => uint[]) public tweetsOf;
    mapping(address => Message[]) private conversations;
    mapping(address => address[]) public following;
    mapping(address => mapping(address => bool)) public isFollowing;
    mapping(address => mapping(address => bool)) public operators;

    uint nextId;
    uint nextMsgId;

    function _createtweet(address _from, string memory _content) internal {
        tweets[nextId] = Tweet({
            id: nextId,
            author: _from,
            content: _content,
            createdAt: block.timestamp
        });
        tweetsOf[_from].push(nextId);
        nextId++;
    }
    function _sendMessage(
        address _from,
        address _to,
        string memory _message
    ) internal {
        Message memory message = Message({
            id: nextMsgId,
            from: _from,
            to: _to,
            content: _message,
            createdAt: block.timestamp
        });
        conversations[_from].push(message);
        nextMsgId++;
    }
    function tweet(string memory _content) public {
        _createtweet(msg.sender, _content);
    }

    function tweet(address _from, string memory _content) public {
        require(operators[_from][msg.sender], "Not Authorised to tweet ");
        _createtweet(_from, _content);
    }
    function sendMessage(address _to, string memory _message) public {
        _sendMessage(msg.sender, _to, _message);
    }
    function sendMessage(
        address _from,
        address _to,
        string memory _message
    ) public {
        require(
            operators[_from][msg.sender],
            "Not Authorised to send message "
        );
        _sendMessage(_from, _to, _message);
    }
    function followUser(address _user) public {
        require(_user != msg.sender, "You cannot follow yourself");
        require(!isFollowing[msg.sender][_user], "Already following");
        following[msg.sender].push(_user);
        isFollowing[msg.sender][_user] = true;
    }

    function getLatestTweets(uint count) public view returns (Tweet[] memory) {
        require(count > 0 && count <= nextId, "invalid count number");
        Tweet[] memory _tweets = new Tweet[](count);
        uint start = nextId - count;
        for (uint i = 0; i < count; i++) {
            _tweets[i] = tweets[start + i];
        }
        return _tweets;
    }

    function getLatestTweetsOfUser(
        address _user,
        uint _count
    ) public view returns (Tweet[] memory) {
        uint numberOfTweets = tweetsOf[_user].length;
        require(_count > 0 && _count <= numberOfTweets, "invalid count number");
        Tweet[] memory _tweets = new Tweet[](_count);
        uint start = numberOfTweets - _count;
        uint j = 0;
        for (uint i = start; i < numberOfTweets; i++) {
            _tweets[j] = tweets[tweetsOf[_user][i]];
            j++;
        }
        return _tweets;
    }
    function setOperator(address _operator, bool _status) public {
        operators[msg.sender][_operator] = _status;
    }
}
