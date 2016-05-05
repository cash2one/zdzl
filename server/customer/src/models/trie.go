package models

import (
	// "log"
	"strings"
)

type Trie struct {
	Size int
	root *node
}

func NewTrie() *Trie {
	return &Trie{0, newNode('\u0000')}
}

func (t *Trie) Insert(a ...string) {
	for _, s := range a {
		n := t.root
		for _, r := range s {
			child := n.subNode(r)
			if child == nil {
				child = newNode(r)
				n.children = append(n.children, child)
			}
			n = child
		}
		if !n.isWord {
			n.isWord = true
			t.Size++
		}
	}
}

func (t *Trie) Contains(s string) bool {
	n := t.root
	for _, r := range s {
		n = n.subNode(r)
		if n == nil {
			return false
		}
	}
	return n.isWord
}

func (t *Trie) Search(s string) []string {
	n := t.root
	for _, r := range s {
		next := n.subNode(r)
		if next == nil {
			return nil
		}
		n = next
	}

	a := make([]string, 0)
	ch := walker(n, s)
	for w := range ch {
		a = append(a, w)
	}
	return a
}

func (t *Trie) Replaces(s string, r string) string {
	tmp := s
	for _, sItem := range s {
		sRet := t.Search(string(sItem))
		if sRet != nil {
			for _, item := range sRet {
				tmpR := r
				for i := 1; i < len([]rune(item)); i++ {
					tmpR += r
				}
				tmp = strings.Replace(tmp, string(item), tmpR, -1)
			}
		}
	}
	return tmp
}

type node struct {
	r        rune
	isWord   bool
	children []*node
}

func newNode(r rune) *node {
	return &node{r, false, make([]*node, 0)}
}

func (n *node) subNode(r rune) *node {
	for _, child := range n.children {
		if child.r == r {
			return child
		}
	}
	return nil
}

func walker(n *node, s string) <-chan string {
	ch := make(chan string)
	go func() {
		walk(n, ch, s)
		close(ch)
	}()
	return ch
}

func walk(n *node, ch chan string, s string) {
	if n.isWord {
		ch <- s
	}
	for _, child := range n.children {
		walk(child, ch, s+string(child.r))
	}
}
