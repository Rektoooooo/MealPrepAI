import Testing
import Foundation
@testable import MealPrepAI

struct GroceryListTests {

    @Test func progressCalculatesCorrectly() {
        let list = GroceryList()
        let item1 = GroceryItem(isChecked: true)
        let item2 = GroceryItem(isChecked: false)
        let item3 = GroceryItem(isChecked: true)
        list.items = [item1, item2, item3]

        #expect(list.progress > 0.66)
        #expect(list.progress < 0.67)
    }

    @Test func progressZeroWhenEmpty() {
        let list = GroceryList()
        list.items = []
        #expect(list.progress == 0)
    }

    @Test func checkedCountReturnsCorrectValue() {
        let list = GroceryList()
        let item1 = GroceryItem(isChecked: true)
        let item2 = GroceryItem(isChecked: false)
        list.items = [item1, item2]

        #expect(list.checkedCount == 1)
    }

    @Test func totalCountReturnsItemCount() {
        let list = GroceryList()
        list.items = [GroceryItem(), GroceryItem(), GroceryItem()]
        #expect(list.totalCount == 3)
    }

    @Test func itemsByCategoryGroupsCorrectly() {
        let list = GroceryList()
        let item1 = GroceryItem()
        let ing1 = Ingredient(name: "Apple", category: .produce)
        item1.ingredient = ing1

        let item2 = GroceryItem()
        let ing2 = Ingredient(name: "Chicken", category: .meat)
        item2.ingredient = ing2

        list.items = [item1, item2]
        let grouped = list.itemsByCategory

        #expect(grouped[.produce]?.count == 1)
        #expect(grouped[.meat]?.count == 1)
    }
}
