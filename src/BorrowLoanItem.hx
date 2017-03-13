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

class BorrowLoanItem implements dci.Context
{
    public function new(loanItem, borrower) {
        this.listOfCards = Data.libraryCards;
        this.listOfItems = Data.libraryItems;
        this.listOfLoans = Data.libraryLoans;
        this.loanItem = loanItem;
        this.borrower = borrower;
    }
    
    public function borrow() : BorrowLoanItemStatus {
        return if(!listOfItems.hasLoanItem())
            InvalidLoanItem;
        else if(!listOfCards.hasBorrowerID())
            InvalidBorrower;
        else if(listOfLoans.hasBorrowedLoanItem())
            ItemAlreadyBorrowed;
        else {
            var loan = new LibraryLoan({
                borrowerRfid: borrower.rfid,
                loanItemRfid: loanItem.rfid,
                created: Date.now(),
                returnDate: Date.now().delta(loanItem.loanTimeDays * 24 * 60 * 60 * 1000)
            });
            listOfLoans.push(loan);
            Ok;
        }
    }

    @role var listOfLoans : {
        public function iterator() : Iterator<LibraryLoan>;
        public function push(loan : LibraryLoan) : Int;

        public function hasBorrowedLoanItem() : Bool {
            return self.exists(function(loan) return loan.loanItemRfid == loanItem.rfid && loan.returnDate.getTime() > Date.now().getTime());
        }
    }

    @role var listOfCards : {
        public function iterator() : Iterator<Card>;

        public function hasBorrowerID() : Bool {
            return self.exists(function(card) return card.rfid == borrower.rfid);
        }
    }

    @role var listOfItems : {
        public function iterator() : Iterator<LoanItem>;

        public function hasLoanItem() : Bool {
            return self.exists(function(item) return item.rfid == loanItem.rfid);
        }
    }    
    
    @role var loanItem : {
        public var rfid(default, set) : String;
        public var loanTimeDays(default, set) : Int;
    }

    @role var borrower : {
        public var rfid(default, set) : String;
    }    
}