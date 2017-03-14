import Data.LibraryLoan;
import Data.LoanItem;
import Data.Card;

using DateTools;

enum BorrowLoanItemStatus {
    Ok;
    ItemAlreadyBorrowed;
    InvalidBorrower;
    InvalidLoanItem;
}

/**
 *  For borrowing a single loan item.
 *  Note that this Context can be used in any system, not just BorrowLibraryItems.
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
        return if(!listOfItems.hasLoanItem())
            InvalidLoanItem;
        else if(!listOfLibraryCards.hasBorrowerID())
            InvalidBorrower;
        else if(listOfLoans.hasBorrowedLoanItem())
            ItemAlreadyBorrowed;
        else {
            var loan = new LibraryLoan({
                borrowerRfid: borrower.id(),
                loanItemRfid: loanItem.id(),
                created: Date.now(),
                returnDate: loanItem.returnDateFromToday()
            });
            listOfLoans.addLoan(loan);
            Ok;
        }
    }

    @role var listOfLoans : {
        public function iterator() : Iterator<LibraryLoan>;
        public function push(loan : LibraryLoan) : Int;

        public function hasBorrowedLoanItem() : Bool {
            return self.exists(function(loan) {
                return loan.loanItemRfid == loanItem.id() && loan.returnDate.getTime() > Date.now().getTime();
            });
        }
        
        public function addLoan(loan : LibraryLoan)
            self.push(loan);
    }

    @role var listOfLibraryCards : {
        public function iterator() : Iterator<Card>;

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
        
        public function returnDateFromToday() 
            return Date.now().delta(self.loanTimeDays * 24 * 60 * 60 * 1000);
    }

    @role var borrower : {
        public var rfid(default, set) : String;

        public function id() 
            return rfid;
    }    
}