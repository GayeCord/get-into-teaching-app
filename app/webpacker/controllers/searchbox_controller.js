import { Controller } from "stimulus"
import accessibleAutocomplete from 'accessible-autocomplete'
import Redacter from '../javascript/redacter'

export default class extends Controller {
  static inputId = 'searchbox__input'
  static openedClass = 'searchbox--opened'
  static targets = ['searchbar']

  searchQuery = null

  connect() {
    this.setupAccessibleAutocomplete()
  }

  disconnect() {
    if (this.autocompleteWrapper)
      this.autocompleteWrapper.remove()

    this.clearAnalyticsSubmitter() ;
  }

  toggle(ev) {
    ev.preventDefault()
    this.element.classList.toggle(this.constructor.openedClass)

    if (this.element.classList.contains(this.constructor.openedClass) && this.inputField)
      this.inputField.focus() ;
  }

  get autocompleteWrapper() {
    return this.searchbarTarget.querySelector(".autocomplete__wrapper")
  }

  get inputField() {
    return this.searchbarTarget.querySelector("input")
  }

  setupAccessibleAutocomplete() {
    accessibleAutocomplete({
      element: this.searchbarTarget,
      id: this.constructor.inputId,
      displayMenu: 'overlay',
      minLength: 2,
      source: this.performXhrSearch.bind(this),
      confirmOnBlur: false,
      onConfirm: this.onConfirm.bind(this),
      templates: {
        inputValue: this.inputValueTemplate.bind(this),
        suggestion: this.formatResults.bind(this)
      }
    })
  }

  searchParams(query) {
    return encodeURIComponent("search[search]") + "=" + encodeURIComponent(query) ;
  }

  performXhrSearch(query, callback) {
    this.searchQuery = query
    this.scheduleSubmissionToAnalytics()

    let request = new XMLHttpRequest()
    request.open('GET', '/search.json?' + this.searchParams(query), true)
    request.timeout = 10 * 1000
    request.onreadystatechange = function () {
      if (request.readyState === XMLHttpRequest.DONE && request.status === 200) {
        const results = JSON.parse(request.responseText)
        callback(results)
      }
    }

    request.send()
  }

  onConfirm(chosen) {
    if (chosen && chosen.link) {
      if (this.analyticsSubmitter)
        this.sendToAnalytics()

      Turbolinks.visit(chosen.link)
    }
  }

  inputValueTemplate(result) {
    if (result)
      return result.title
  }

  formatResults(result) {
    if (result)
      return result.html
  }

  get redactedQuery() {
    return (new Redacter(this.searchQuery)).redacted
  }

  get google_analytics_id() {
    const ga_id = document.body.getAttribute('data-analytics-ga-id')

    if (ga_id && ga_id.trim() != "")
      return ga_id
  }

  scheduleSubmissionToAnalytics() {
    this.clearAnalyticsSubmitter() ;

    this.analyticsSubmitter = window.setTimeout(this.sendToAnalytics.bind(this), 2000)
  }

  sendToAnalytics() {
    this.clearAnalyticsSubmitter() ;

    if (window.ga && this.google_analytics_id) {
      window.ga('create', this.google_analytics_id, 'auto')
      window.ga('set', 'title', 'Get into Teaching: Search Get into Teaching')
      window.ga('set', 'page', '/search?' + this.searchParams(this.redactedQuery))
      window.ga('send', 'pageview')
    }
  }

  clearAnalyticsSubmitter() {
    if (!this.analyticsSubmitter)
      return

    window.clearTimeout(this.analyticsSubmitter)
    this.analyticsSubmitter = null
  }
}