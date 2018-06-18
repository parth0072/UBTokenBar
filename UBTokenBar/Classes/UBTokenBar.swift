//
//  UBTokenBar.swift
//  UBTokenBar
//
//  Copyright (c) 2017 Uber Technologies, Inc.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit

let tokenBarCellReuseIdentifier = "TBTokenBarCellReuseIdentifier"
let tokenBarTextInputCellReuseIdentifier = "TBTokenBarTextInputCellReuseIdentifier"

open class UBTokenBar: UIView, UICollectionViewDataSource, UICollectionViewDelegate, UBTokenBarTextFieldDelegate, UBTokenBarCollectionViewCellDelegate {
    private var collectionView: UICollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: UBTokenBarCollectionViewFlowLayout())

    // Change this to update the collection view layout
    public var collectionViewLayout: UICollectionViewLayout = UBTokenBarCollectionViewFlowLayout() {
        didSet {
            self.collectionView.setCollectionViewLayout(collectionViewLayout, animated: false)
        }
    }

    // The collection view cell reuse class for the embedded collection view, change this to register your own custom class to customize the token appearance
    public var collectionViewCellReuseClass: AnyClass = UBTokenBarCollectionViewCell.self {
        didSet {
            self.collectionView.register(collectionViewCellReuseClass, forCellWithReuseIdentifier: tokenBarCellReuseIdentifier)
        }
    }

    // The collection view cell reuse class for text input field cell in the embedded collection view, change this to register your own custom class to customize the text field
    public var collectionViewTextInputCellReuseClass: AnyClass = UBTokenBarTextFieldCollectionViewCell.self {
        didSet {
            self.collectionView.register(collectionViewTextInputCellReuseClass, forCellWithReuseIdentifier: tokenBarTextInputCellReuseIdentifier)
        }
    }

    // Change this text to customize the UBTokenBar placeholder text
    public var placeholderText: String = "Enter some text and hit return"

    public weak var delegate: UBTokenBarDelegate?

    private(set) public var tokens: [UBToken] = []

    private weak var tokenBarTextField: UITextField?

    public init(collectionViewLayout: UICollectionViewLayout = UBTokenBarCollectionViewFlowLayout(), collectionViewCellReuseClass: AnyClass = UBTokenBarRemovableCollectionViewCell.self, collectionViewTextInputCellReuseClass: AnyClass = UBTokenBarTextFieldCollectionViewCell.self, frame: CGRect = CGRect.zero) {
        super.init(frame: frame)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.collectionViewLayout = collectionViewLayout
        self.collectionViewCellReuseClass = collectionViewCellReuseClass
        self.collectionView.frame = frame
        self.collectionView.register(self.collectionViewCellReuseClass, forCellWithReuseIdentifier: tokenBarCellReuseIdentifier)
        self.collectionViewTextInputCellReuseClass = collectionViewTextInputCellReuseClass
        self.collectionView.register(self.collectionViewTextInputCellReuseClass, forCellWithReuseIdentifier: tokenBarTextInputCellReuseIdentifier)
        self.collectionView.setCollectionViewLayout(self.collectionViewLayout, animated: false)
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.collectionView.backgroundColor = UIColor.clear
        self.collectionView.alwaysBounceVertical = true
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false

        if self.tokenBarIsRTL() {
            self.collectionView.transform = CGAffineTransform(scaleX: -1, y: 1)
        }

        self.addSubview(self.collectionView)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported.")
    }

    open override func updateConstraints() {
        let leadingConstraint = NSLayoutConstraint(item: self.collectionView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0)
        let trailingConstraint = NSLayoutConstraint(item: self.collectionView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0)
        let topConstraint = NSLayoutConstraint(item: self.collectionView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: self.collectionView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0)
        self.addConstraints([leadingConstraint, trailingConstraint, topConstraint, bottomConstraint])

        super.updateConstraints()
    }

    open override func resignFirstResponder() -> Bool {
        self.tokenBarTextField?.resignFirstResponder()
        return super.resignFirstResponder()
    }

    open override func becomeFirstResponder() -> Bool {
        self.tokenBarTextField?.becomeFirstResponder()
        return super.becomeFirstResponder()
    }

    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.tokenBarTextField?.becomeFirstResponder()
        super.touchesBegan(touches, with: event)
    }

    /// General public methods

    public func contentSize() -> CGSize {
        return self.collectionViewLayout.collectionViewContentSize
    }

    /// UICollectionViewDataSource methods

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Add 1 to render the text input field cell
        return self.tokens.count + 1
    }

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let tokenAtIndexPath = self.tokenAtIndexPath(indexPath: indexPath) {
            // Could find a token, lets render it in the token bar
            if let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: tokenBarCellReuseIdentifier, for: indexPath) as? UBTokenBarCollectionViewCell {
                cell.token = tokenAtIndexPath
                cell.delegate = self
                return cell
            } else {
                assert(false, "Expected to dequeue a cell of type UBTokenBarCollectionViewCell or a subclass of it for reuseIdentifier '\(tokenBarCellReuseIdentifier)'!")
                return UICollectionViewCell()
            }
        } else {
            // This is the text input cell for the token bar
            if let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: tokenBarTextInputCellReuseIdentifier, for: indexPath) as? UBTokenBarTextFieldCollectionViewCell {
                self.tokenBarTextField = cell.textField
                if self.tokens.count > 0 {
                    cell.textField.placeholder = nil
                    self.collectionView.alwaysBounceVertical = true
                } else {
                    cell.textField.placeholder = self.placeholderText
                    self.collectionView.alwaysBounceVertical = false
                }
                cell.computedWidth = 0
                cell.delegate = self
                cell.updateConstraints()
                return cell
            } else {
                assert(false, "Expected to dequeue a cell of type UBTokenBarTextFieldCollectionViewCell or a subclass of it for reuseIdentifier '\(tokenBarTextInputCellReuseIdentifier)'!")
            }
        }
        return UICollectionViewCell()
    }

    /// UICollectionViewDelegate methods

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

    }

    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {

    }

    public func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {

    }

    public func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {

    }
    
    

    /// Token managment methods

    public func reloadTokenBar() {
        let previousSize = self.contentSize()
        self.collectionView.reloadData()
        self.collectionViewLayout.invalidateLayout()
        DispatchQueue.main.async {
            self.collectionView.performBatchUpdates({
            }, completion: { (complete) in
                if !previousSize.equalTo(self.contentSize()) {
                    self.delegate?.tokenBarSizeDidChange(newTokenBarSize: self.collectionViewLayout.collectionViewContentSize)
                }
                let delayTime = DispatchTime.now() + 0.2
                DispatchQueue.main.asyncAfter(deadline: delayTime, execute: {
                    let indexPath = IndexPath(item: self.collectionView.numberOfItems(inSection: 0) - 1, section: 0)
                    self.collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
                })
            })
        }
    }

    /**
     Call this method to set the tokens of the token bar

     - Parameter tokens: The tokens you wish to set on the token bar
     */
    public func setTokens(tokens: [UBToken]) {
        self.tokens = tokens
        self.reloadTokenBar()
    }

    /**
     Call this method to add a token to the token bar

     - Parameter token: The token you wish to add to the UBTokenBar
     */
    public func addToken(token: UBToken) {
        if let delegate = self.delegate {
            if delegate.shouldAddToken(tokenToAdd: token) {
                self.tokenBarTextField?.text = nil
                self.delegate?.tokenBarTextDidChange(newTokenBarText: "")
                self.tokens.append(token)
                self.reloadTokenBar()
            }
        } else {
            self.tokenBarTextField?.text = nil
            self.delegate?.tokenBarTextDidChange(newTokenBarText: "")
            self.tokens.append(token)
            self.reloadTokenBar()
        }
    }

    /**
     Call this method to remove a token to the token bar

     - Parameter token: The token you wish to remove from the UBTokenBar
     */
    public func removeToken(token: UBToken) {
        if let delegate = self.delegate {
            if delegate.shouldDeleteToken(tokenToDelete: token) {
                if let tokenIndex = self.tokens.index(of: token) {
                    self.tokenBarTextField?.text = nil
                    self.delegate?.tokenBarTextDidChange(newTokenBarText: "")
                    self.tokens.remove(at: tokenIndex)
                }
                self.reloadTokenBar()
            }
        } else {
            if let tokenIndex = self.tokens.index(of: token) {
                self.tokenBarTextField?.text = nil
                self.delegate?.tokenBarTextDidChange(newTokenBarText: "")
                self.tokens.remove(at: tokenIndex)
            }
            self.reloadTokenBar()
        }
    }

    private func tokenAtIndexPath(indexPath: IndexPath) -> UBToken? {
        if indexPath.item < tokens.count {
            return self.tokens[indexPath.item]
        }
        return nil
    }

    /// TBTokenBarCollectionViewCellDelegate

    internal func tokenRemoveButtonTapped(token: UBToken, cell: UBTokenBarCollectionViewCell) {
        self.removeToken(token: token)
    }

    /// TBTokenBarTextFieldCellDelegate

    internal func textFieldShouldReturn(textField: UITextField) -> Bool {
        if let currentTextFieldText = textField.text {
            if let newToken = self.delegate?.tokenForTokenBarText(currentTokenBarText: currentTextFieldText) {
                self.addToken(token: newToken)
                textField.text = nil
                self.delegate?.tokenBarTextDidChange(newTokenBarText: "")
                if !self.becomeFirstResponder() {
                    let delayTime = DispatchTime.now() + 0.2
                    DispatchQueue.main.asyncAfter(deadline: delayTime, execute: {
                        let _ = self.becomeFirstResponder()
                    })
                }
                return true
            }
        }
        return false
    }

    internal func textFieldBackspaceOnEmptyText() {
        guard let lastToken = self.tokens.last else {
            return
        }
        self.removeToken(token: lastToken)
        let _ = self.becomeFirstResponder()
    }

    internal func textFieldTextDidChange(text: String) {
        self.delegate?.tokenBarTextDidChange(newTokenBarText: text)
    }
}
