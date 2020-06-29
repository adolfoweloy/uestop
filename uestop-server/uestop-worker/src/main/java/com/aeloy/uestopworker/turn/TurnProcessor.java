package com.aeloy.uestopworker.turn;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.cloud.aws.messaging.listener.annotation.SqsListener;
import org.springframework.stereotype.Component;

@Component
public class TurnProcessor {

    private static final Logger log = LoggerFactory.getLogger(TurnProcessor.class);

    @SqsListener("game-turn")
    public void process(Turn turn) {
        log.info("processing turn: " + turn.getTurnId());
    }
}
