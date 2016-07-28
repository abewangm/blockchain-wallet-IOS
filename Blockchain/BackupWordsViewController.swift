//
//  BackupWordsViewController.swift
//  Blockchain
//
//  Created by Sjors Provoost on 19-05-15.
//  Copyright (c) 2015 Qkos Services Ltd. All rights reserved.
//

import UIKit

class BackupWordsViewController: UIViewController, SecondPasswordDelegate, UIScrollViewDelegate {
    
    @IBOutlet weak var wordsScrollView: UIScrollView?
    @IBOutlet weak var wordsPageControl: UIPageControl?
    @IBOutlet weak var wordsProgressLabel: UILabel?
    @IBOutlet weak var wordLabel: UILabel?
    @IBOutlet weak var screenShotWarningLabel: UILabel?
    @IBOutlet weak var previousWordButton: UIButton!
    @IBOutlet weak var nextWordButton: UIButton!
    @IBOutlet var summaryLabel: UILabel?

    var wallet : Wallet?
    var wordLabels: [UILabel]?
    var isVerifying = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updatePreviousWordButton()

        setupTopInstructionLabel()
        
        setupBottomInstructionLabel()
        
        wallet!.addObserver(self, forKeyPath: "recoveryPhrase", options: .New, context: nil)
        
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        
        wordLabel!.text = ""
        
        updateCurrentPageLabel(0)
        
        wordsScrollView!.clipsToBounds = true
        wordsScrollView!.contentSize = CGSizeMake(CGFloat(Constants.Defaults.NumberOfRecoveryPhraseWords) * wordLabel!.frame.width, wordLabel!.frame.height)
        wordsScrollView!.userInteractionEnabled = false

        wordLabels = [UILabel]()
        wordLabels?.insert(wordLabel!, atIndex: 0)
        for i in 1 ..< Constants.Defaults.NumberOfRecoveryPhraseWords {
            let offset: CGFloat = CGFloat(i) * wordLabel!.frame.width
            let x: CGFloat = wordLabel!.frame.origin.x + offset
            let label = UILabel(frame: CGRectMake(x, wordLabel!.frame.origin.y, wordLabel!.frame.size.width, wordLabel!.frame.size.height))
            label.adjustsFontSizeToFitWidth = true
            label.font = wordLabel!.font
            label.textColor = wordLabel!.textColor
            label.textAlignment = wordLabel!.textAlignment

            wordLabel!.superview?.addSubview(label)
            
            wordLabels?.append(label)
        }
        
        if wallet!.needsSecondPassword(){
            self.performSegueWithIdentifier("secondPasswordForBackup", sender: self)
        } else {
            wallet!.getRecoveryPhrase(nil)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView .animateWithDuration(0.3, animations: { () -> Void in
            self.previousWordButton!.frame.origin = CGPointMake(0,self.view.frame.size.height-self.previousWordButton!.frame.size.height);
            self.nextWordButton!.frame.origin = CGPointMake(self.view.frame.size.width-self.previousWordButton!.frame.size.width, self.view.frame.size.height-self.previousWordButton!.frame.size.height);
        })
    }
    
    func setupTopInstructionLabel() {
        let blackTextBeginning = NSAttributedString(string:  NSLocalizedString("Write the following 12 words onto a ", comment:""), attributes:
            [NSForegroundColorAttributeName: UIColor.blackColor()])
        
        let boldText = NSAttributedString(string: NSLocalizedString("piece of paper.", comment:""), attributes:[NSForegroundColorAttributeName: UIColor.blackColor(), NSFontAttributeName : UIFont.boldSystemFontOfSize(14.0)])
        
        let blackTextEnd = NSAttributedString(string:  NSLocalizedString(" Anyone with access to your Recovery Phrase has access to your bitcoin so be sure to keep it offline somewhere very safe and secure.", comment:""), attributes:
            [NSForegroundColorAttributeName: UIColor.blackColor()])
        
        let finalText = NSMutableAttributedString(attributedString: blackTextBeginning)
        finalText.appendAttributedString(boldText)
        finalText.appendAttributedString(blackTextEnd)
        summaryLabel?.attributedText = finalText
    }
    
    func setupBottomInstructionLabel() {
        let blackText = NSAttributedString(string:  NSLocalizedString("It is important to make sure you write down your words exactly as they appear here and ", comment:""), attributes:[NSForegroundColorAttributeName: UIColor.blackColor()])
        
        let boldText = NSAttributedString(string: NSLocalizedString("in this order.", comment:""), attributes: [NSForegroundColorAttributeName: UIColor.blackColor(), NSFontAttributeName : UIFont.boldSystemFontOfSize(14.0)])
        
        let finalText = NSMutableAttributedString(attributedString: blackText)
        finalText.appendAttributedString(boldText)
        screenShotWarningLabel?.attributedText = finalText
    }
    
    func updatePreviousWordButton() {
        if wordsPageControl!.currentPage == 0 {
            previousWordButton?.enabled = false
            previousWordButton?.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
        } else {
            previousWordButton?.enabled = true
            previousWordButton?.setTitleColor(UIColor.darkGrayColor(), forState: .Normal)
        }
    }

    @IBAction func previousWordButtonTapped(sender: UIButton) {
        if (wordsPageControl!.currentPage > 0) {
            let pagePosition = wordLabel!.frame.width * CGFloat(wordsPageControl!.currentPage-1)
            wordsScrollView?.setContentOffset(CGPointMake(pagePosition, wordsScrollView!.contentOffset.y), animated: true)
        }
    }
    
    @IBAction func nextWordButtonTapped(sender: UIButton) {
        if let count = wordLabels?.count {
            if (wordsPageControl!.currentPage == count-1) {
                performSegueWithIdentifier("backupVerify", sender: nil)
            } else if wordsPageControl!.currentPage < count-1 {
                let pagePosition = wordLabel!.frame.width * CGFloat(wordsPageControl!.currentPage+1)
                wordsScrollView?.setContentOffset(CGPointMake(pagePosition, wordsScrollView!.contentOffset.y), animated: true)
            }
        }
    }
    
    func updateCurrentPageLabel(page: Int) {
        wordsProgressLabel!.text = NSLocalizedString(NSString(format: "Word %@ of %@", String(page + 1), String((Constants.Defaults.NumberOfRecoveryPhraseWords))) as String, comment: "")
        if let count = wordLabels?.count {
            if wordsPageControl!.currentPage == count-1 {
                nextWordButton?.backgroundColor = Constants.Colors.BlockchainBlue
                nextWordButton?.setTitleColor(UIColor.whiteColor(), forState: .Normal)
                nextWordButton?.setTitle(NSLocalizedString("Done", comment:""), forState: .Normal)
            } else if wordsPageControl!.currentPage == count-2 {
                nextWordButton?.backgroundColor = Constants.Colors.SecondaryGray
                nextWordButton?.setTitleColor(UIColor.darkGrayColor(), forState: .Normal)
                nextWordButton?.setTitle(NSLocalizedString("Next word", comment:""), forState: .Normal)
            }
            
            updatePreviousWordButton()
        }
    }
    
    // MARK: - Words Scrollview
    func scrollViewDidScroll(scrollView: UIScrollView) {
        // Determine page number:
        let pageWidth = scrollView.frame.size.width
        let fractionalPage = Float(scrollView.contentOffset.x / pageWidth)
        let page: Int = lroundf(fractionalPage)
        
        wordsPageControl!.currentPage = page
        
        updateCurrentPageLabel(page)
    }

    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
    }
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "secondPasswordForBackup" {
            let vc = segue.destinationViewController as! SecondPasswordViewController
            vc.delegate = self
            vc.wallet = wallet
        } else if segue.identifier == "backupVerify" {
            let vc = segue.destinationViewController as! BackupVerifyViewController
            vc.wallet = wallet
            vc.isVerifying = false
        }
    }
    
    func didGetSecondPassword(password: String) {
        wallet!.getRecoveryPhrase(password)
    }
    
    func returnToRootViewController(completionHandler: () -> Void ) {
        self.navigationController?.popToRootViewControllerWithHandler({ () -> () in
            completionHandler()
        })
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String: AnyObject]?, context: UnsafeMutablePointer<Void>) {
        let words = wallet!.recoveryPhrase.componentsSeparatedByString(" ")
        for i in 0 ..< Constants.Defaults.NumberOfRecoveryPhraseWords {
            wordLabels![i].text = words[i]
        }

    }
    
    deinit {
        wallet!.removeObserver(self, forKeyPath: "recoveryPhrase", context: nil)
    }
}