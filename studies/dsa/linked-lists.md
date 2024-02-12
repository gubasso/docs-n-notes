# Linked-lists

<!-- toc -->

- [LeetCode Problems](#leetcode-problems)
- [Traverse a linked list](#traverse-a-linked-list)

<!-- tocstop -->

## LeetCode Problems

- p206_reverse_linked_list
- p2130_maximum_twin_sum_of_a_linked_list
- p24_swap_nodes_in_pairs

## Traverse a linked list

**javascript**

```js
let getSum = head => {
  let ans = 0
  while(head) {
    ans += head.val
    head = head.next
  }
  return ans
}
```

**rust**

```rs
fn getSum(head: Option<Box<ListNode>>) -> i32 {
  let mut ans = 0;
  let mut pointer = &head;
  while let Some(node) = pointer {
    ans += node.val;
    pointer = &node.next;
  }
  ans
}
```
