import React from 'react'
import PropTypes from 'prop-types'

/**
 * Example of component to be used as a fallback in case of errors
 * captured by ErrorBoundary
 * @param {*} error
 */
const ErrorComponent = ({ error }) => {
  return (
    <>
      <div>Something went wrong!</div>
      <strong>{error.message}</strong>
    </>
  )
}
ErrorComponent.propTypes = {
  error: PropTypes.object,
}

export default ErrorComponent
