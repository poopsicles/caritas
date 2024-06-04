import Blob "mo:base/Blob";
import Random "mo:base/Random";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import List "mo:base/List";
import Text "mo:base/Text";
import HashMap "mo:base/HashMap";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Iter "mo:base/Iter";
import Ledger "icp-ledger-interface";

actor {
  type Account = Ledger.Account;

  class User(name : Text, principal : Principal, subaccount : ?[Nat8]) {
    public let username : Text = name;
    public let userPrincipal : Principal = principal;
    public let account : Account = {
      owner = principal;
      subaccount = subaccount;
    };
  };

  class Charity(name : Text, description : Text, mission : Text, accountIdentifier : Account) {
    public let charityName : Text = name;
    public let charityDescription : Text = description;
    public let charityMission : Text = mission;
    public let charityAccountIdentifier : Account = accountIdentifier;

  };

  type Advice = {
    tag : Text;
    content : Text;
    time : Time.Time;
    user : Principal;
  };

  class Donation(from : Principal, amount : Nat, charity : Text) {
    public let donor : Principal = from;
    public let donationAmount : Nat = amount;
    public let charityName : Text = charity;
    public let donationTime : Time.Time = Time.now();
  };

  var charityMap = HashMap.HashMap<Text, Charity>(5, Text.equal, Text.hash);
  var donationMap = HashMap.HashMap<Text, List.List<Donation>>(5, Text.equal, Text.hash);
  var userMap = HashMap.HashMap<Principal, User>(5, Principal.equal, Principal.hash);

  stable var charityMapList : List.List<(Text, Charity)> = List.nil();
  stable var donationMapList : List.List<(Text, List.List<Donation>)> = List.nil();

  // Dump the entire map into a stable list
  system func preupgrade() {
    charityMapList := Iter.toList(charityMap.entries());
    donationMapList := Iter.toList(donationMap.entries());
  };

  // Pour the entire list back into the map
  system func postupgrade() {
    for ((charityName, charity) in List.toIter(charityMapList)) {
      charityMap.put(charityName, charity);
    };
    for ((donationName, donation) in List.toIter(donationMapList)) {
      donationMap.put(donationName, donation);
    };
  };

  private func get_random_principal() : async Principal {
    let random_data = await Random.blob();
    return Principal.fromBlob(Blob.fromArray(Array.subArray(Blob.toArray(random_data), 0, 29)));
  };

  private func create_account(principal : ?Principal) : async Account {
    switch (principal) {
      case (?principal) {
        return { owner = principal; subaccount = null };
      };
      case (null) {
        return { owner = await get_random_principal(); subaccount = null };
      };
    };
  };

  public shared (msg) func create_user_wallet(username : Text, subaccount : ?[Nat8]) : async Result.Result<User, Text> {
    switch (userMap.get(msg.caller)) {
      case (null) {

        let user = User(username, msg.caller, subaccount);
        userMap.put(msg.caller, user);

        #ok(user);
      };
      case (?user) {
        return #err("User already exists");
      };
    };
  };

  public func create_charity(principal : ?Principal, name : Text, description : Text, mission : Text) : async Charity {
    let account = await create_account(principal);
    let charity = Charity(name, description, mission, account);

    let _ = charityMap.put(name, charity);

    return charity;
  };

  public query func getCharityByName(name : Text) : async ?Charity {
    return charityMap.get(name);
  };

  public query func getNumberOfCharities() : async Nat {
    return charityMap.size();
  };

  public shared func transfer(from_subaccount : ?[Nat8], to : Account, amount : Nat) : async () {
    let _transferArgs : Ledger.TransferArg = {
      to = to;
      fee = null;
      amount = amount;
      created_at_time = null;
      memo = null;
      from_subaccount = from_subaccount;
    };
  };

  public func donate(userPrincipal : Principal, from_subaccount : ?[Nat8], amount : Nat, charityName : Text) : async Result.Result<Donation, Text> {
    let charity = await getCharityByName(charityName);
    switch (charity) {
      case (?charity) {
        let donation = Donation(userPrincipal, amount, charityName);
        await transfer(from_subaccount, charity.charityAccountIdentifier, amount);
        switch (donationMap.get(charityName)) {
          //TODO: MOVE THE MONEY
          case (?donations) {
            let _ = List.push(donation, donations);
          };
          case (null) {
            donationMap.put(charityName, List.fromArray([donation]));
          };
        };
        return #ok(donation);
      };
      case (null) {
        return #err("Charity not found");
      };
    };
  };

  public func getDonationsForCharity(charityName : Text) : async List.List<Donation> {
    switch (donationMap.get(charityName)) {
      case (?donations) {
        return donations;
      };
      case (null) {
        return List.fromArray([]);
      };
    };
  };

  public query func getTotalDonationAmountForCharityByName(charityName : Text) : async Result.Result<Nat, Text> {
    if (Text.size(charityName) == 0) {
      return #err("Charity name cannot be empty");
    };
    let donations = donationMap.get(charityName);
    switch (donations) {
      case (?donations) {
        return #ok(List.foldLeft<Donation, Nat>(donations, 0, func(acc, donation) { acc + donation.donationAmount }));
      };
      case (null) {
        return #err(charityName # " has no recorded donations");
      };
    };
  };

  public query func greet(name : Text) : async Text {
    return "Hello, " # name # "!";
  };
};
