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
        this.librarian = this;
    }
    
    public function borrow() : BorrowLoanItemStatus {
        return librarian.checkBorrowerId();
    }

    @role var librarian : {
        public function checkBorrowerId() {
            var id = borrower.id();
            return if(!listOfLibraryCards.hasBorrowerId(id))
                InvalidBorrower;
            else
                checkLoanItemId();
        }

        function checkLoanItemId() {
            var id = loanItem.id();
            return if(!listOfItems.hasLoanItem(id))
                InvalidLoanItem;
            else if(listOfLoans.hasLoanItemAlready(id))
                ItemAlreadyBorrowed;
            else 
                addLoan();
        }

        function addLoan() {
            var loanTime = loanItem.loanTime();
            var loan = new LibraryLoan({
                borrowerRfid: borrower.id(),
                loanItemRfid: loanItem.id(),
                created: Date.now(),
                returnDate: Date.now().delta(loanTime * 24 * 60 * 60 * 1000)
            });
            listOfLoans.addLoan(loan);
            return Ok(loan);
        }
    }

    @role var listOfLoans : {
        function iterator() : Iterator<LibraryLoan>;
        function push(loan : LibraryLoan) : Int;

        public function hasLoanItemAlready(id) : Bool {
            return self.exists(function(loan) {
                return loan.loanItemRfid == id && loan.returnDate.getTime() > Date.now().getTime();
            });
        }
        
        public function addLoan(loan : LibraryLoan)
            self.push(loan);
    }

    @role var listOfLibraryCards : {
        function iterator() : Iterator<LibraryCard>;

        public function hasBorrowerId(id) : Bool {
            return self.exists(function(card) return card.rfid == id);
        }
    }

    @role var listOfItems : {
        function iterator() : Iterator<LoanItem>;

        public function hasLoanItem(id) : Bool {
            return self.exists(function(item) return item.rfid == id);
        }
    }    
    
    @role var loanItem : {
        var rfid(default, set) : String;
        var loanTimeDays(default, set) : Int;

        public function id() 
            return rfid;

        public function loanTime()
            return loanTimeDays;        
    }

    @role var borrower : {
        var rfid(default, set) : String;

        public function id() 
            return rfid;
    }    
}