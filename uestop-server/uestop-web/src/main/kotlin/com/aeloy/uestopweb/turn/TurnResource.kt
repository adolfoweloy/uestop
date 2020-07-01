package com.aeloy.uestopweb.turn

import org.springframework.cloud.aws.messaging.core.QueueMessagingTemplate
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("turn")
class TurnResource constructor(val queueMessagingTemplate: QueueMessagingTemplate) {

    @PostMapping
    fun finish(@RequestBody turn: Turn): ResponseEntity<Void> {
        return try {
            queueMessagingTemplate.convertAndSend("game-turn", turn)
            ResponseEntity.ok().build()
        } catch (e: Exception) {
            ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build()
        }
    }

}
