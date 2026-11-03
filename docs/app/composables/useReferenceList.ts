import type { Ref } from 'vue'

// Shared behavior for the expandable reference lists (environment variables, commands):
// one open row mirrored in the URL hash, arrow-key movement between rows, copy buttons
// that work on plain-HTTP previews, and scrolling that clears the sticky header and toolbar.
export function useReferenceList(options: {
  names: Ref<string[]>
  list: Ref<HTMLElement | null>
  toolbar: Ref<HTMLElement | null>
  searchInput: Ref<{ focus: () => void } | null>
}) {
  const open = ref('')
  const stickyTop = ref(0)
  const toolbarHeight = ref(0)
  const rowOffset = computed(() => stickyTop.value + toolbarHeight.value + 8)

  function anchor(name: string) {
    return name.toLowerCase().replaceAll('_', '-')
  }

  function toggle(name: string) {
    open.value = open.value === name ? '' : name
    history.replaceState(history.state, '', open.value ? `#${anchor(open.value)}` : `${location.pathname}${location.search}`)
  }

  function rows() {
    return [...(options.list.value?.querySelectorAll<HTMLButtonElement>('[data-row]') ?? [])]
  }

  function focusRow(index: number) {
    rows()[index]?.focus()
  }

  function moveFocus(event: KeyboardEvent, step: number) {
    const all = rows()
    const index = all.indexOf(event.currentTarget as HTMLButtonElement) + step
    if (index < 0) return options.searchInput.value?.focus()
    all[index]?.focus()
  }

  // The Clipboard API needs HTTPS, so fall back to execCommand on plain HTTP previews.
  const { copy } = useClipboard({ legacy: true })
  const copiedKey = ref('')

  async function copyText(key: string, text: string) {
    await copy(text)
    copiedKey.value = key
    setTimeout(() => {
      if (copiedKey.value === key) copiedKey.value = ''
    }, 2000)
  }

  function linkTo(name: string) {
    return `${location.origin}${location.pathname}#${anchor(name)}`
  }

  async function openFromHash() {
    const target = options.names.value.find(name => `#${anchor(name)}` === location.hash)
    if (!target) return
    open.value = target
    await nextTick()
    document.getElementById(anchor(target))?.scrollIntoView({ block: 'start' })
  }

  defineShortcuts({
    '/': () => options.searchInput.value?.focus()
  })

  onMounted(async () => {
    // The site header is sticky and its height changes with the banner, so measure it.
    const header = document.querySelector<HTMLElement>('div.sticky.top-0')
    const measure = () => {
      stickyTop.value = header?.offsetHeight ?? 0
      const element = options.toolbar.value
      toolbarHeight.value = element && getComputedStyle(element).position === 'sticky' ? element.offsetHeight : 0
    }
    measure()
    if (header) useResizeObserver(header, measure)
    useResizeObserver(options.toolbar, measure)

    await openFromHash()
    useEventListener(window, 'hashchange', openFromHash)
  })

  return { open, stickyTop, rowOffset, anchor, toggle, focusRow, moveFocus, copiedKey, copyText, linkTo }
}
