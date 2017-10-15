package contexts;

import Data.LibraryLoan;
import Data.LoanItem;
import Data.LibraryCard;

enum BorrowLoanItemStatus {
    Ok(loan : LibraryLoan);
    ItemAlreadyBorrowed;
    InvalidBorrower;
    InvalidLoanItem;
}

/**
 *  Use case for borrowing a single loan item.
 *  Note that this Context can be used in any system, not just BorrowLibraryItems.
 *  
 *  @see https://docs.google.com/spreadsheets/d/1TSpjKUhjvP9pMRukt_mInHVbdQWsXHzFjSymQ3VyGmE/edit#gid=1759452953
 */
class BorrowLoanItem implements dci.Context
{
    public function new(loanItem, borrower) {
        this.listOfLibraryCards = Data.libraryCards;
        this.listOfItems = Data.libraryItems;
        this.listOfLoans = Data.libraryLoans;
        this.loanItem = loanItem;
        this.borrower = borrower;
    }
    
    public function borrow() : BorrowLoanItemStatus {
        return if(!listOfLibraryCards.hasBorrowerID())
            InvalidBorrower;
        else if(!listOfItems.hasLoanItem())
            InvalidLoanItem;
        else if(listOfLoans.hasLoanItemAlready())
            ItemAlreadyBorrowed;
        else {
            var loanTime = loanItem.loanTime();
            var loan = new LibraryLoan({
                borrowerRfid: borrower.id(),
                loanItemRfid: loanItem.id(),
                created: Date.now(),
                returnDate: Date.now().delta(loanTime * 24 * 60 * 60 * 1000)
            });
            listOfLoans.addLoan(loan);
            Ok(loan);
        }
    }

    @role var listOfLoans : {
        public function iterator() : Iterator<LibraryLoan>;
        public function push(loan : LibraryLoan) : Int;

        public function hasLoanItemAlready() : Bool {
            return self.exists(function(loan) {
                return loan.loanItemRfid == loanItem.id() && loan.returnDate.getTime() > Date.now().getTime();
            });
        }
        
        public function addLoan(loan : LibraryLoan)
            self.push(loan);
    }

    @role var listOfLibraryCards : {
        public function iterator() : Iterator<LibraryCard>;

        public function hasBorrowerID() : Bool {
            return self.exists(function(card) return card.rfid == borrower.id());
        }
    }

    @role var listOfItems : {
        public function iterator() : Iterator<LoanItem>;

        public function hasLoanItem() : Bool {
            return self.exists(function(item) return item.rfid == loanItem.id());
        }
    }    
    
    @role var loanItem : {
        public var rfid(default, set) : String;
        public var loanTimeDays(default, set) : Int;

        public function id() 
            return rfid;

        public function loanTime()
            return loanTimeDays;        
    }

    @role var borrower : {
        public var rfid(default, set) : String;

        public function id() 
            return rfid;
    }    
}