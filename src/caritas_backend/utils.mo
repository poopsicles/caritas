import Text "mo:base/Text";
import List "mo:base/List";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Random "mo:base/Random";
import Result "mo:base/Result";

actor {
  stable var charities = List.nil<Charity>();
  stable var orphanages = List.nil<Orphanage>();

  type Charity = {
    name : Text;
    city : Text;
    book_balance : Nat;
    total_out : Nat;
    total_in : Nat;
  };

  type Orphanage = {
    name : Text;
    city : Text;
    book_balance : Nat;
    total_out : Nat;
    total_in : Nat;
    orphans : List.List<Orphan>;
  };

  type Orphan = {
    name : Text;
    age : Nat;
    hobby : Text;
  };

  public query func list_charities() : async List.List<Charity> {
    charities;
  };

  public func add_charity(name : Text, city : Text) : async Result.Result<Nat, Text> {
    let random = Random.Finite(await Random.blob());
    let bal = random.range(12);

    switch (bal) {
      case (null) {
        return #err("Unable to get a source of entropy.");
      };
      case (?b) {
        let new_charity : Charity = {
          name = name;
          city = city;
          book_balance = 100 + b;
          total_in = 0;
          total_out = 0;
        };

        charities := List.push(new_charity, charities);
        return #ok(List.size(charities));
      };
    };
  };

  public func add_orphanage(name : Text, city : Text) : async Result.Result<Nat, Text> {
    let random = Random.Finite(await Random.blob());
    let bal = random.range(12);

    switch (bal) {
      case (null) {
        return #err("Unable to get a source of entropy.");
      };
      case (?b) {
        let new_orphanage : Orphanage = {
          name = name;
          city = city;
          book_balance = 100 + b;
          total_in = 0;
          total_out = 0;
          orphans = List.nil();
        };

        orphanages := List.push(new_orphanage, orphanages);
        return #ok(List.size(orphanages));
      };
    };
  };
};
