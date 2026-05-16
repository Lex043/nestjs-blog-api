import { Module } from '@nestjs/common';
import { ArticlesController } from './articles.controller';
import { ArticlesService } from './articles.service';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Article } from 'src/entities/article.entity';

@Module({
    imports: [TypeOrmModule.forFeature([Article])],
    controllers: [ArticlesController],
    providers: [ArticlesService],
    exports: [ArticlesService, TypeOrmModule],
})
export class ArticlesModule {}
