// SPDX-License-Identifier:MIT
pragma solidity ^0.8.21;

import {Test} from "forge-std/Test.sol";
import {Twitter} from "../src/Twitter.sol";

contract TwitterTest is Test {
    Twitter twitter;

    address user1 = address(1);
    address user2 = address(2);
    address operator = address(3);

    function setUp() public {
        twitter = new Twitter();
        vm.prank(user1);
        twitter.tweet("First Tweet from user1");

        vm.prank(user2);
        twitter.tweet("First Tweet from user2");
    }
    function test_Tweet() public {
        vm.prank(user1);
        twitter.tweet("Second Tweet from user1");

        Twitter.Tweet[] memory tweets = twitter.getLatestTweetsOfUser(user1, 2);
        assertEq(tweets.length, 2);
        assertEq(tweets[1].content, "Second Tweet from user1");
    }
    function test_setOperator() public {
        vm.prank(user1);
        twitter.setOperator(operator, true);
        vm.prank(operator);
        twitter.tweet(user1, "Operator tweeting for user1");
        Twitter.Tweet[] memory tweets = twitter.getLatestTweetsOfUser(user1, 2);
        assertEq(tweets[1].content, "Operator tweeting for user1");
        assertEq(tweets.length, 2);
    }
    function test_followUser() public {
        vm.prank(user1);
        twitter.followUser(user2);
        assertEq(twitter.isFollowing(user1, user2), true);
    }
    function test_sendMessageWithOperator() public {
        vm.prank(user1);
        twitter.setOperator(operator, true);

        vm.prank(operator);
        twitter.sendMessage(user1, user2, "Operator sent this");
    }
    function test_getLatestTweets() public {
        vm.prank(user1);
        twitter.tweet("Another tweet");

        Twitter.Tweet[] memory latest = twitter.getLatestTweets(2);
        assertEq(latest.length, 2);
        assertEq(latest[1].content, "Another tweet");
    }

    function test_getLatestTweetsInvalidCount() public {
        vm.expectRevert("invalid count number");
        twitter.getLatestTweets(100);
    }
    function test_getLatestTweetsOfUserInvalidCount() public {
        vm.expectRevert("invalid count number");
        twitter.getLatestTweetsOfUser(user1, 10);
    }
}
