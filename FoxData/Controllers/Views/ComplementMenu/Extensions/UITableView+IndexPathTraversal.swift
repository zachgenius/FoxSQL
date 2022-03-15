import UIKit

// MARK: Convenience accessors to fetch indexPath for focusable rows.
extension UITableView {
    public var indexPathForFirstRow: IndexPath? {
        return self.numberOfSections > 0 && self.numberOfRows(inSection: 0) > 0 ? IndexPath(row: 0, section: 0) : nil
    }
    
    public var indexPathForLastRow: IndexPath? {
        let numberOfSections = self.numberOfSections
        
        guard numberOfSections > 0 else { return nil }
        let sectionIndex = numberOfSections - 1
        
        let numberOfRowsInLastSection = self.numberOfRows(inSection: sectionIndex)
        
        guard numberOfRowsInLastSection > 0 else { return nil }
        let rowIndex = numberOfRowsInLastSection - 1
        
        let indexPath = IndexPath(row: rowIndex, section: sectionIndex)
        
        return indexPath
    }
    
    public func indexPathForRow(startingAt indexPath: IndexPath, offsetBy rowOffset: Int) -> IndexPath? {
        let offsetRowIndex = indexPath.row + rowOffset
        let numberOfSections = self.numberOfSections
        
        var determinedRowIndex: Int = offsetRowIndex
        var determinedSectionIndex: Int = indexPath.section
        
        while true {
            if !(0..<numberOfSections).contains(determinedSectionIndex) {
                return nil
            }
            
            if determinedRowIndex < 0 {
                determinedSectionIndex -= 1
                
                if determinedSectionIndex < 0 {
                    return nil
                }
                
                determinedRowIndex = self.numberOfRows(inSection: determinedSectionIndex) + determinedRowIndex
            } else if determinedRowIndex > self.numberOfRows(inSection: determinedSectionIndex) - 1 {
                let overflowedCount = determinedRowIndex - self.numberOfRows(inSection: determinedSectionIndex)
                
                determinedSectionIndex += 1
                
                if determinedSectionIndex >= numberOfSections {
                    return nil
                }
                
                determinedRowIndex = overflowedCount
            } else {
                return IndexPath(row: determinedRowIndex, section: determinedSectionIndex)
            }
        }
    }
}
